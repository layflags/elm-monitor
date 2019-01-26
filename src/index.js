const install = () => {
  if (!window.__REDUX_DEVTOOLS_EXTENSION__) throw Error('Redux DevTools n/a');
  if (!window.Worker) throw Error('Worker n/a');

  const devtools = window.__REDUX_DEVTOOLS_EXTENSION__.connect({
    features: {
      pause: true, // start/pause recording of dispatched actions
      export: true, // export history of actions in a file
    },
  });

  const worker = new Worker('./worker.js');
  worker.onmessage = event => {
    const { type, payload } = event.data;
    switch(type) {
      case 'init':
        devtools.init(payload);
        break;
      case 'update':
        devtools.send(payload.action, payload.state);
        break;
      default:
        // ignore
    }
  }

  const consoleLog = console.log.bind(console);
  console.log = (...args) => {
    const match =
      typeof args[0] === 'string' &&
      args[0].match(/^\[Monitor:(init|update)\]: (.+)$/);

    if (match) {
      const [, type, content] = match;
      worker.postMessage({ type, content });
    } else {
      consoleLog(...args);
    }
  }
}

export default install;
