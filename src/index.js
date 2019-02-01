const Elm = require('./parser')

const isCtor = a => typeof a === 'string' && /^⟨.+⟩$/.test(a)

const app = Elm.Main.worker();

const parse = (content, onSuccess) => {
  return new Promise(resolve => {
    app.ports.sendParsedData.subscribe(resolve)
    app.ports.listenToInput.send(content);
  })
}

const expandType = data => {
  if (isCtor(data)) return [data]
  const [a, b, ...rest] = data
  if (!isCtor(a)) throw Error('`a` not a type string')
  if (isCtor(b) && rest.length === 0) {
    return [`${a}:${b}`]
  }
  if (Array.isArray(b) && isCtor(b[0]) && b.length <= 2 && rest.length === 0) {
    return expandType([`${a}:${b[0]}`, ...b.slice(1)])
  }
  return [a, b, ...rest]
}

const toFSA = action => {
  const [type, ...payload] = expandType(action)
  return payload.length > 0
    ? { type: `${type}*`, payload: payload.length > 1 ? payload : payload[0] }
    : { type }
}

const install = () => {
  if (window.__REDUX_DEVTOOLS_EXTENSION__ && window.console) {
    const devtools = window.__REDUX_DEVTOOLS_EXTENSION__.connect({
      features: {
        pause: true, // start/pause recording of dispatched actions
        export: true // export history of actions in a file
      }
    })
    const consoleLog = window.console.log.bind(window.console)
    window.console.log = async (...args) => {
      const match =
        typeof args[0] === 'string' &&
        args[0].match(/^\[Monitor:(init|update)\]: (.+)$/)
      if (match) {
        const [, type, content] = match

        switch (type) {
          case 'init':
            {
              const result = await parse(content);
              devtools.init(result)
            }
            break
          case 'update':
            {
              const [action, state] = await parse(content)
              devtools.send(toFSA(action), state)
            }
            break
          default:
          // will never happen
        }
      } else {
        consoleLog(...args)
      }
    }
  }
}

export default install
