import { worker } from '@electric-sql/pglite/worker';

interface InitMeta {
  dbName: string;
  fsBundle: Blob;
  vectorBundlePath: string;
  wasmModule: WebAssembly.Module;
}

worker({
  async init(options) {
    const { wasmModule, fsBundle, vectorBundlePath, dbName } = options.meta as InitMeta;
    const { PGlite } = await import('@electric-sql/pglite');

    return new PGlite({
      dataDir: `idb://${dbName}`,
      extensions: {
        vector: {
          name: 'pgvector',
          setup: async (pglite, options) => {
            return { bundlePath: new URL(vectorBundlePath), options };
          },
        },
      },
      fsBundle,
      relaxedDurability: true,
      wasmModule,
    });
  },
});
