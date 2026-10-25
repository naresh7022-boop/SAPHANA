#!/usr/bin/env node
/**
 * Root Launcher for RF Screen Development Deployment Script
 * Delegates execution to 'RF Screen Development/deploy/deploy_rf_program.cjs'
 */
const path = require("path");
const { main } = require(path.resolve(__dirname, "../RF Screen Development/deploy/deploy_rf_program.cjs"));

main().catch(err => {
  console.error("Fatal deployment error:", err);
  process.exit(1);
});
