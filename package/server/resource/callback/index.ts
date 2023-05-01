import { cache } from '../cache';

const activeEvents: Record<string, (...args) => void> = {};

onNet(`__ox_cb_${cache.resource}`, (key: string, ...args: any) => {
  const resolve = activeEvents[key];
  return resolve && resolve(...args);
});

export function triggerClientCallback<T = unknown>(
  eventName: string,
  playerId: number,
  ...args: any
): Promise<T> | void {
  let key: string;

  do {
    key = `${eventName}:${Math.floor(Math.random() * (100000 + 1))}:${playerId}`;
  } while (activeEvents[key]);

  emitNet(`__ox_cb_${eventName}`, playerId, cache.resource, key, ...args);

  return new Promise<T>((resolve) => {
    activeEvents[key] = resolve;
  });
}

export function triggerClientCallbackLatent<T = unknown>(
  eventName: string,
  playerId: number,
  bps: number,
  ...args: any
): Promise<T> | void {
  let key: string;

  do {
    key = `${eventName}:${Math.floor(Math.random() * (100000 + 1))}:${playerId}`;
  } while (activeEvents[key]);

  TriggerLatentClientEvent(`__ox_cb_${eventName}`, playerId, bps, cache.resource, key, ...args);

  return new Promise<T>((resolve) => {
    activeEvents[key] = resolve;
  })
}

export function onClientCallback(eventName: string, cb: (playerId: number, ...args) => any) {
  onNet(`__ox_cb_${eventName}`, (resource: string, key: string, ...args) => {
    const src = source;
    let response: any;

    try {
      response = cb(src, ...args);
    } catch (e: any) {
      console.error(`an error occurred while handling callback event ${eventName}`);
      console.log(`^3${e.stack}^0`);
    }

    emitNet(`__ox_cb_${resource}`, src, key, response);
  });
}

export function onClientCallbackLatent(eventName: string, bps: number, cb: (playerId: number, ...args) => any) {
  onNet(`__ox_cb_${eventName}`, (resource: string, key: string, ...args) => {
    const src = source;
    let response: any;

    try {
      response = cb(src, ...args);
    } catch (e: any) {
      console.error(`an error occurred while handling latent callback event ${eventName}`);
      console.log(`^3${e.stack}^0`);
    }

    TriggerLatentClientEvent(`__ox_cb_${resource}`, src, bps, key, response)
  })
}
