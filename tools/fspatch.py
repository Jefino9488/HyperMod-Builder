#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os


def scanfs(file) -> dict:
    filesystem_config = {}
    with open(file, "r") as file_:
        for i in file_.readlines():
            try:
                filepath, *other = i.strip().split()
            except Exception or BaseException:
                print(f"[W] Skip {i}")
                continue
            filesystem_config[filepath] = other
            if (long := len(other)) > 4:
                print(f"[W] {i[0]} has too much data-{long}.")
    return filesystem_config


def scan_dir(folder) -> list:
    allfiles = [
        "/",
        "/lost+found",
        f"/{os.path.basename(folder)}/lost+found",
        f"/{os.path.basename(folder)}/",
    ]
    if os.name == "nt":
        yield os.path.basename(folder).replace("\\", "")
    elif os.name == "posix":
        yield os.path.basename(folder).replace("/", "")
    else:
        yield os.path.basename(folder)
    for root, dirs, files in os.walk(folder, topdown=True):
        for dir_ in dirs:
            yield os.path.join(root, dir_).replace(
                folder, os.path.basename(folder)
            ).replace("\\", "/")
        for file in files:
            yield os.path.join(root, file).replace(
                folder, os.path.basename(folder)
            ).replace("\\", "/")
        for rv in allfiles:
            yield rv


def islink(file) -> str:
    if os.name == "nt":
        if not os.path.isdir(file):
            with open(file, "rb") as f:
                if f.read(10) == b"!<symlink>":
                    return f.read().decode("utf-16")[:-1]
                else:
                    return ""
    elif os.name == "posix":
        if os.path.islink(file):
            return os.readlink(file)
        else:
            return ""


def fs_patch(fs_file, dir_path) -> tuple:  # 接收两个字典对比
    new_fs = {}
    new_add = 0
    r_fs = {}
    print("FsPatcher: Load origin %d" % (len(fs_file.keys())) + " entries")
    for i in scan_dir(os.path.abspath(dir_path)):
        if not i.isprintable():
            tmp = ""
            for c in i:
                tmp += c if c.isprintable() else "*"
            i = tmp
        if " " in i:
            i = i.replace(" ", "*")
        if fs_file.get(i):
            new_fs[i] = fs_file[i]
        else:
            if r_fs.get(i):
                continue
            if os.name == "nt":
                filepath = os.path.abspath(
                    dir_path + os.sep + ".." + os.sep + i.replace("/", "\\")
                )
            elif os.name == "posix":
                filepath = os.path.abspath(dir_path + os.sep + ".." + os.sep + i)
            else:
                filepath = os.path.abspath(dir_path + os.sep + ".." + os.sep + i)
            if os.path.isdir(filepath):
                uid = "0"
                if "system/bin" in i or "system/xbin" in i or "vendor/bin" in i:
                    gid = "2000"
                else:
                    gid = "0"
                mode = "0755"  # dir path always 755
                config = [uid, gid, mode]
            elif not os.path.exists(filepath):
                config = ["0", "0", "0755"]
            elif islink(filepath):
                uid = "0"
                if ("system/bin" in i) or ("system/xbin" in i) or ("vendor/bin" in i):
                    gid = "2000"
                else:
                    gid = "0"
                if ("/bin" in i) or ("/xbin" in i):
                    mode = "0755"
                elif ".sh" in i:
                    mode = "0750"
                else:
                    mode = "0644"
                link = islink(filepath)
                config = [uid, gid, mode, link]
            elif ("/bin" in i) or ("/xbin" in i):
                uid = "0"
                mode = "0755"
                if ("system/bin" in i) or ("system/xbin" in i) or ("vendor/bin" in i):
                    gid = "2000"
                else:
                    gid = "0"
                    mode = "0755"
                if ".sh" in i:
                    mode = "0750"
                else:
                    for s in [
                        "/bin/su",
                        "/xbin/su",
                        "disable_selinux.sh",
                        "daemon",
                        "ext/.su",
                        "install-recovery",
                        "installed_su",
                        "bin/rw-system.sh",
                        "bin/getSPL",
                    ]:
                        if s in i:
                            mode = "0755"
                config = [uid, gid, mode]
            else:
                uid = "0"
                gid = "0"
                mode = "0644"
                config = [uid, gid, mode]
            print(f"Add [{i}{config}]")
            r_fs[i] = 1
            new_add += 1
            new_fs[i] = config
    return new_fs, new_add


def main(dir_path, fs_config):
    new_fs, new_add = fs_patch(scanfs(os.path.abspath(fs_config)), dir_path)
    with open(fs_config, "w", encoding="utf-8", newline="\n") as f:
        f.writelines(
            [i + " " + " ".join(new_fs[i]) + "\n" for i in sorted(new_fs.keys())]
        )
    print("FsPatcher: Add %d" % new_add + " entries")


def Usage():
    print("Usage:")
    print("%s <folder> <fs_config>" % (sys.argv[0]))
    print("    This script will auto patch fs_config")


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        Usage()
        sys.exit()
    if os.path.isdir(sys.argv[1]) or os.path.isfile(sys.argv[2]):
        main(sys.argv[1], sys.argv[2])
        print("Done!")
    else:
        print(
            "The path or filetype you have given may wrong, please check it wether correct."
        )
        Usage()
