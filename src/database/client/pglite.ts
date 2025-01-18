import { PGliteWorker } from '@electric-sql/pglite/worker';

interface InitMeta {
  dbName: string;
  fsBundle: Blob;
  vectorBundlePath: string;
  wasmModule: WebAssembly.Module;
}

export const initPgliteWorker = async (meta: InitMeta) => {
  const worker = await PGliteWorker.create(
    new Worker(new URL('pglite.worker.ts', import.meta.url)),
    { meta },
  );

  // 监听 worker 状态变化
  worker.onLeaderChange(() => {
    console.log('Worker leader changed, isLeader:', worker?.isLeader);
  });

  return worker as PGliteWorker;
};
