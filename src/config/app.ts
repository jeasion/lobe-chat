import { createEnv } from '@t3-oss/env-nextjs';
import { z } from 'zod';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace NodeJS {
    interface ProcessEnv {
      ACCESS_CODE?: string;
    }
  }
}

export const getAppConfig = () => {
  const ACCESS_CODES = process.env.ACCESS_CODE?.split(',').filter(Boolean) || [];

  return createEnv({
    client: {
      NEXT_PUBLIC_BASE_PATH: z.string(),
    },
    runtimeEnv: {
      ACCESS_CODES: ACCESS_CODES as any,

      AGENTS_INDEX_URL: !!process.env.AGENTS_INDEX_URL
        ? process.env.AGENTS_INDEX_URL
        : 'https://chat-agents.lobehub.com',

      DEFAULT_AGENT_CONFIG: process.env.DEFAULT_AGENT_CONFIG || '',

      NEXT_PUBLIC_BASE_PATH: process.env.NEXT_PUBLIC_BASE_PATH || '',

      PLUGINS_INDEX_URL: !!process.env.PLUGINS_INDEX_URL
        ? process.env.PLUGINS_INDEX_URL
        : 'https://chat-plugins.lobehub.com',

      PLUGIN_SETTINGS: process.env.PLUGIN_SETTINGS,
      SITE_URL: process.env.SITE_URL,
    },
    server: {
      ACCESS_CODES: z.any(z.string()).optional(),

      AGENTS_INDEX_URL: z.string().url(),

      DEFAULT_AGENT_CONFIG: z.string(),

      PLUGINS_INDEX_URL: z.string().url(),
      PLUGIN_SETTINGS: z.string().optional(),

      SITE_URL: z.string().optional(),
    },
  });
};

export const appEnv = getAppConfig();
