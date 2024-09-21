import { useState, useRef } from 'react';
import './App.css';
import { Octokit } from 'https://esm.sh/@octokit/core';

const App = () => {
  const [url, setUrl] = useState('');
  const [region, setRegion] = useState('Global');
  const [corePatch, setCorePatch] = useState('false');

  const formRef = useRef(null);
  const GITHUB_TOKEN = import.meta.env.VITE_GITHUB_TOKEN;
  const REPO_OWNER = 'Jefino9488';
  const REPO_NAME = 'HyperMod-Builder';
  const HYPER_BUILDER = 'Hyper_Builder.yml';

  const octokit = new Octokit({
    auth: GITHUB_TOKEN,
  });

  const handleSubmit = async (e) => {
    e.preventDefault();

    const inputs = { URL: url, region, core: corePatch };

    try {
      const response = await octokit.request('POST /repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches', {
        owner: REPO_OWNER,
        repo: REPO_NAME,
        workflow_id: HYPER_BUILDER,
        ref: 'master',
        inputs: inputs,
      });

      if (response.status === 204) {
        window.alert('HyperMod build started! Please wait for 10-15 minutes and check the releases page.');
        resetForm();
      } else {
        console.error('Error triggering GitHub Action:', response.status);
      }
    } catch (error) {
      console.error('Error triggering GitHub Action:', error);
    }
  };

  const resetForm = () => {
    setUrl('');
    setRegion('Global');
    setCorePatch('false');
  };

  const handleRedirect = () => {
    window.open('https://github.com/Jefino9488/HyperMod-Builder/releases', '_blank');
  };

  const handleRedirectBuild = () => {
    window.open(`https://github.com/Jefino9488/HyperMod-Builder/actions/workflows/${HYPER_BUILDER}`, '_blank');
  };

  return (
      <div id="root">
        <h1 id="h">HyperMod ROM Build</h1>
        <form ref={formRef} onSubmit={handleSubmit}>
          <h2>Hyper Mod ROM Details</h2>
          <label htmlFor="url-input">Recovery ROM direct link:</label>
          <input
              type="url"
              id="url-input"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              required
          />

          <label htmlFor="region-select">Select Region:</label>
          <select
              id="region-select"
              value={region}
              onChange={(e) => setRegion(e.target.value)}
              required
          >
            <option value="CN">CN</option>
            <option value="Global">Global</option>
          </select>

          <label htmlFor="core-select">Apply Core Patch:</label>
          <select
              id="core-select"
              value={corePatch}
              onChange={(e) => setCorePatch(e.target.value)}
              required
          >
            <option value="false">No</option>
            <option value="true">Yes</option>
          </select>

          <button type="submit">Start Build</button>
        </form>

        <p>All builds are available on the releases page</p>
        <div id="root1">
          <button onClick={handleRedirect}>Go to releases</button>
          <button onClick={handleRedirectBuild}>Build Status</button>
        </div>
      </div>
  );
};

export default App;
