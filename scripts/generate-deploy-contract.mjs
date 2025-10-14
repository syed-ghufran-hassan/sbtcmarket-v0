import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const inputPath = path.join(projectRoot, 'contracts', 'sbtcmarket-v0.clar');
const outputPath = path.join(projectRoot, 'contracts', 'sbtcmarket-v0-deploy2.clar');

const replacements = [
  {
    search: '(use-trait pyth-storage-trait .pyth-traits-v2.storage-trait)',
    replace:
      "(use-trait pyth-storage-trait 'STR738QQX1PVTM6WTDF833Z18T8R0ZB791TCNEFM.pyth-traits-v2.storage-trait)",
  },
  {
    search: '(use-trait pyth-decoder-trait .pyth-traits-v2.decoder-trait)',
    replace:
      "(use-trait pyth-decoder-trait 'STR738QQX1PVTM6WTDF833Z18T8R0ZB791TCNEFM.pyth-traits-v2.decoder-trait)",
  },
  {
    search: '(use-trait wormhole-core-trait .wormhole-traits-v2.core-trait)',
    replace:
      "(use-trait wormhole-core-trait 'STR738QQX1PVTM6WTDF833Z18T8R0ZB791TCNEFM.wormhole-traits-v2.core-trait)",
  },
  {
    search: '.sbtc-token',
    replace: "'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token",
  },
  {
    search: '.pyth-oracle-v4',
    replace:
      "'STR738QQX1PVTM6WTDF833Z18T8R0ZB791TCNEFM.pyth-oracle-v4",
  },
];

function generateDeployContract() {
  let content = readFileSync(inputPath, 'utf8');

  for (const { search, replace } of replacements) {
    if (!content.includes(search)) {
      throw new Error(`Input file missing expected snippet: ${search}`);
    }
    content = content.split(search).join(replace);
  }

  writeFileSync(outputPath, content);
  console.log(`Generated deploy contract at ${path.relative(projectRoot, outputPath)}`);
}

generateDeployContract();
