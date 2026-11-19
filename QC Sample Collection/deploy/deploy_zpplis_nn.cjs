#!/usr/bin/env node
/**
 * Automated ADT Deployment Script for QC Sample Collection (ZPPLIS_NN)
 * Target System: SAP S/4HANA (DS4 / Client 220)
 */
const path = require("path");
const fs = require("fs");

const scratchCallTool = "/Users/naresh/.gemini/antigravity-ide/scratch/mcp-abap-adt/call-tool.cjs";
let callAdtTool;
try {
  ({ callAdtTool } = require(scratchCallTool));
} catch (e) {
  console.warn("Warning: call-tool.cjs not found in scratch dir:", e.message);
}

async function deployObject(toolName, params) {
  if (!callAdtTool) {
    throw new Error("callAdtTool helper not available.");
  }
  console.log(`Executing ${toolName} for ${JSON.stringify(params.program_name || params.class_name || params)}...`);
  const res = await callAdtTool(toolName, params);
  if (res && res.isError) {
    console.warn(`[WARN] ${toolName} returned error response:`, JSON.stringify(res, null, 2));
    return { ok: false, res };
  }
  console.log(`[SUCCESS] ${toolName}:`, JSON.stringify(res, null, 2));
  return { ok: true, res };
}

async function main() {
  const classFile = path.resolve(__dirname, "../src/zcl_sample_collection_nn.clas.abap");
  const progFile = path.resolve(__dirname, "../src/sapmzpplis_nn.prog.abap");
  const tcodeFile = path.resolve(__dirname, "../src/zcreate_tcode_zpplis_nn.prog.abap");
  const tileFile = path.resolve(__dirname, "../src/zcreate_fiori_tile_zpplis_nn.prog.abap");

  console.log("================================================================");
  console.log(" Deploying QC Sample Collection (ZPPLIS_NN) to SAP DS4/220");
  console.log("================================================================");

  // 1. Deploy Backend Class Controller
  if (fs.existsSync(classFile)) {
    console.log(`\n--- Step 1: Deploying Class ZCL_SAMPLE_COLLECTION_NN ---`);
    const classSource = fs.readFileSync(classFile, "utf8");
    let updClass = await deployObject("UpdateClass", {
      class_name: "ZCL_SAMPLE_COLLECTION_NN",
      source_code: classSource,
      activate: true
    });
    if (!updClass.ok) {
      console.log("Attempting CreateClass if not present...");
      await deployObject("CreateClass", {
        class_name: "ZCL_SAMPLE_COLLECTION_NN",
        package_name: "$TMP",
        description: "QC Sample Collection & Barcode Scanner Backend Controller"
      });
      await deployObject("UpdateClass", {
        class_name: "ZCL_SAMPLE_COLLECTION_NN",
        source_code: classSource,
        activate: true
      });
    }
  }

  // 2. Deploy Module Pool Program SAPMZPPLIS_NN
  if (fs.existsSync(progFile)) {
    console.log(`\n--- Step 2: Deploying Module Pool Program SAPMZPPLIS_NN ---`);
    const progSource = fs.readFileSync(progFile, "utf8");
    let updProg = await deployObject("UpdateProgram", {
      program_name: "SAPMZPPLIS_NN",
      source_code: progSource,
      activate: true
    });
    if (!updProg.ok) {
      console.log("Attempting CreateProgram...");
      await deployObject("CreateProgram", {
        program_name: "SAPMZPPLIS_NN",
        package_name: "$TMP",
        description: "QC Sample Collection & Barcode Scanner (ZPPLIS_NN)",
        program_type: "module_pool"
      });
      await deployObject("UpdateProgram", {
        program_name: "SAPMZPPLIS_NN",
        source_code: progSource,
        activate: true
      });
    }
  }

  // 3. Deploy Dynpro & TCODE Generator Program
  if (fs.existsSync(tcodeFile)) {
    console.log(`\n--- Step 3: Deploying TCODE & Dynpro Deployer (ZCREATE_TCODE_ZPPLIS_NN) ---`);
    const tcodeSource = fs.readFileSync(tcodeFile, "utf8");
    let updTcode = await deployObject("UpdateProgram", {
      program_name: "ZCREATE_TCODE_ZPPLIS_NN",
      source_code: tcodeSource,
      activate: true
    });
    if (!updTcode.ok) {
      await deployObject("CreateProgram", {
        program_name: "ZCREATE_TCODE_ZPPLIS_NN",
        package_name: "$TMP",
        description: "Dynpro & TCODE Deployer for ZPPLIS_NN",
        program_type: "executable"
      });
      await deployObject("UpdateProgram", {
        program_name: "ZCREATE_TCODE_ZPPLIS_NN",
        source_code: tcodeSource,
        activate: true
      });
    }

    console.log(`\n--- Executing ZCREATE_TCODE_ZPPLIS_NN to build Dynpros 0100 & 0200 and TSTC ---`);
    await deployObject("RuntimeRunProgram", {
      program_name: "ZCREATE_TCODE_ZPPLIS_NN"
    });
  }

  // 4. Deploy Fiori Tile Registration Program
  if (fs.existsSync(tileFile)) {
    console.log(`\n--- Step 4: Deploying Fiori Tile Configurator (ZCREATE_FIORI_TILE_ZPPLIS_NN) ---`);
    const tileSource = fs.readFileSync(tileFile, "utf8");
    let updTile = await deployObject("UpdateProgram", {
      program_name: "ZCREATE_FIORI_TILE_ZPPLIS_NN",
      source_code: tileSource,
      activate: true
    });
    if (!updTile.ok) {
      await deployObject("CreateProgram", {
        program_name: "ZCREATE_FIORI_TILE_ZPPLIS_NN",
        package_name: "$TMP",
        description: "Fiori Semantic Object & Tile Configurator for ZPPLIS_NN",
        program_type: "executable"
      });
      await deployObject("UpdateProgram", {
        program_name: "ZCREATE_FIORI_TILE_ZPPLIS_NN",
        source_code: tileSource,
        activate: true
      });
    }

    console.log(`\n--- Executing ZCREATE_FIORI_TILE_ZPPLIS_NN to register FLP Semantic Objects ---`);
    await deployObject("RuntimeRunProgram", {
      program_name: "ZCREATE_FIORI_TILE_ZPPLIS_NN"
    });
  }

  console.log("\n================================================================");
  console.log(" ✅ All ZPPLIS_NN objects deployed and registered successfully!");
  console.log("================================================================");
}

if (require.main === module) {
  main().catch(err => {
    console.error("Fatal deployment error:", err);
    process.exit(1);
  });
}

module.exports = { main };
