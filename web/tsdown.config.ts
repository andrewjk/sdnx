import { type UserConfig, defineConfig } from "tsdown";

export default defineConfig({
	entry: ["src/index.ts", "src/bin/index.ts"],
}) satisfies UserConfig as UserConfig;
