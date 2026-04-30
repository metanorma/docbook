#!/usr/bin/env node

import { statSync, existsSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const distDir = join(__dirname, '..', 'dist')
const maxJsBytes = 250 * 1024  // 250KB budget for JS
const maxCssBytes = 120 * 1024 // 120KB budget for CSS

let exitCode = 0

for (const [file, budget] of [['app.iife.js', maxJsBytes], ['app.css', maxCssBytes]]) {
  const filePath = join(distDir, file)
  if (!existsSync(filePath)) {
    console.error(`Missing: ${file}`)
    exitCode = 1
    continue
  }

  const size = statSync(filePath).size
  const kb = (size / 1024).toFixed(1)
  const budgetKb = (budget / 1024).toFixed(0)

  if (size > budget) {
    console.error(`FAIL: ${file} is ${kb}KB (max ${budgetKb}KB)`)
    exitCode = 1
  } else {
    console.log(`OK:   ${file} is ${kb}KB (max ${budgetKb}KB)`)
  }
}

process.exit(exitCode)
