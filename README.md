# HyperMod-`builder` [![HyperMod_Fastboot](https://github.com/Jefino9488/HyperMod-Builder/actions/workflows/Hyper_Builder.yml/badge.svg)](https://github.com/Jefino9488/HyperMod-Builder/actions/workflows/Hyper_Builder.yml)


**`HyperMod-builder`** is a workflow designed to streamline the process of building custom ROMs for various devices. This project allows for easy customization and patching of recovery ROMs based on the region and core patch requirements.

> **Note:** This website is still in **beta**. Features and functionalities are subject to change as development progresses.

## Features
- Automated extraction and patching of official recovery ROMs.
- Device-specific build processes.
- Custom region selection (CN/Global).
- Optional core patch application.
- Automatic repacking and uploading of modified fastboot ROMs.

## Workflow Inputs

| Input      | Description                    | Type     | Options               | Default |
|------------|--------------------------------|----------|-----------------------|---------|
| `URL`      | Official recovery ROM URL      | `string` | N/A                   | N/A     |
| `region`   | Select region for the build    | `choice` | `CN`, `Global`        | N/A     |
| `core`     | Apply core patch               | `choice` | `true`, `false`       | `false` |


## Website for Triggering Workflow
Visit the official [HyperMod Builder](https://jefino9488.github.io/HyperMod-Builder/) to trigger the workflow for building your custom ROM.

## Release Information
Each build generates a release with:
- Device-specific fastboot ROM ZIP.
- Download link for the ROM.
- Changelog with build details.

## Changelog
To see the full changelog navigate to, [CHANGELOG.md](changelog.md).

## Getting Started

1. Fork or clone the repository.
2. Configure the workflow by specifying the `URL`, `region`, and `core` inputs.
3. Run the workflow to generate a modified ROM for your selected device.

## Contributing
Feel free to contribute by submitting issues, bug reports, or pull requests to help improve the project.

## License
This project is licensed under the [MIT License](LICENSE).

---

© 2024 HyperMod_Fastboot Project. All rights reserved.

