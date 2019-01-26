import Parser from './parser';

const isCtor = a => typeof a === 'string' && /^⟨.+⟩$/.test(a)

const expandType = ([a, b, ...rest]) => {
  if (!isCtor(a)) throw Error('`a` not a type string');
  if (isCtor(b) && rest.length === 0) {
    return [`${a}:${b}`];
  }
  if (Array.isArray(b) && isCtor(b[0]) && b.length <= 2 && rest.length === 0) {
    return expandType([`${a}:${b[0]}`, ...b.slice(1)]);
  }
  return [a, b, ...rest];
};

const toFSA = action => {
  const [type, ...payload] = expandType(action);
  return payload.length > 0
    ? { type: `${type}*`, payload: payload.length > 1 ? payload : payload[0] }
    : { type };
};

console.log('[elm-monitor] worker running!');

onmessage = event => {
  const { type, content } = event.data;
  switch (type) {
    case 'init':
      postMessage({ type: 'init', payload: Parser.parse(content) });
      break;
    case 'update':
      {
        const [action, state] = Parser.parse(content);
        postMessage({ type: 'update', payload: {
          action: toFSA(action),
          state
        }});
      }
      break;
    default:
      // ignore
  }
};
