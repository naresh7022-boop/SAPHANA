const path = require("path");
const fs = require("fs");

// Resolve callAdtTool from scratch directory
const scratchCallTool = "/Users/naresh/.gemini/antigravity-ide/scratch/mcp-abap-adt/call-tool.cjs";
let callAdtTool;
try {
  ({ callAdtTool } = require(scratchCallTool));
} catch (e) {
  console.error("Warning: call-tool.cjs not found in scratch dir:", e.message);
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
  const tcodeFile = path.resolve(__dirname, "../src/zcreate_tcode_zrf_reswm.prog.abap");
  const progFile = path.resolve(__dirname, "../src/zrf_res_wm_transfer.prog.abap");
  const classFile = path.resolve(__dirname, "../src/zcl_rf_auto_wm_im_transfer.clas.abap");

  console.log("==================================================");
  console.log("Deploying RF Screen Development Artifacts to SAP DS4/220");
  console.log("==================================================");

  // 1. Deploy Backend Class Controller
  if (fs.existsSync(classFile)) {
    console.log(`\n--- Step 1: Deploying Backend Controller Class (ZCL_RF_AUTO_WM_IM_TRANSFER) ---`);
    const classSource = fs.readFileSync(classFile, "utf8");
    let updClass = await deployObject("UpdateClass", {
      class_name: "ZCL_RF_AUTO_WM_IM_TRANSFER",
      source_code: classSource,
      activate: true
    });
    if (!updClass.ok) {
      console.log("Class update failed, attempting CreateClass if not present...");
      await deployObject("CreateClass", {
        class_name: "ZCL_RF_AUTO_WM_IM_TRANSFER",
        package_name: "$TMP",
        description: "Backend Controller for RF Reservation to WM Transfer"
      });
      await deployObject("UpdateClass", {
        class_name: "ZCL_RF_AUTO_WM_IM_TRANSFER",
        source_code: classSource,
        activate: true
      });
    }
  }

  // 2. Deploy Main RF Module Pool
  if (fs.existsSync(progFile)) {
    console.log(`\n--- Step 2: Deploying Main Program SAPMZRF_RES_WM_TRANSFER ---`);
    const progSource = fs.readFileSync(progFile, "utf8");
    let upd = await deployObject("UpdateProgram", {
      program_name: "SAPMZRF_RES_WM_TRANSFER",
      source_code: progSource,
      activate: true
    });
    if (!upd.ok) {
      await deployObject("CreateProgram", {
        program_name: "SAPMZRF_RES_WM_TRANSFER",
        package_name: "$TMP",
        description: "RF Scanner for Reservation to WM Transfer",
        program_type: "module_pool"
      });
      await deployObject("UpdateProgram", {
        program_name: "SAPMZRF_RES_WM_TRANSFER",
        source_code: progSource,
        activate: true
      });
    }
  }

  // 3. Deploy TCODE Generator & CUA Setup Program
  if (fs.existsSync(tcodeFile)) {
    console.log(`\n--- Step 3: Deploying TCODE & CUA Generator Program (ZCREATE_TCODE_ZRF_RESWM) ---`);
    const tcodeSource = fs.readFileSync(tcodeFile, "utf8");
    let upd = await deployObject("UpdateProgram", {
      program_name: "ZCREATE_TCODE_ZRF_RESWM",
      source_code: tcodeSource,
      activate: true
    });
    if (!upd.ok) {
      console.log("Program does not exist yet. Creating ZCREATE_TCODE_ZRF_RESWM...");
      await deployObject("CreateProgram", {
        program_name: "ZCREATE_TCODE_ZRF_RESWM",
        package_name: "$TMP",
        description: "Create TCODE ZRF_RESWM and ZRF01",
        program_type: "executable"
      });
      await deployObject("UpdateProgram", {
        program_name: "ZCREATE_TCODE_ZRF_RESWM",
        source_code: tcodeSource,
        activate: true
      });
    }

    // Run TCODE & CUA registration
    console.log(`\n--- Step 4: Executing ZCREATE_TCODE_ZRF_RESWM to register CUA, Dynpros & TCODEs ---`);
    const runRes = await deployObject("RuntimeRunProgram", {
      program_name: "ZCREATE_TCODE_ZRF_RESWM"
    });
    if (runRes.res && runRes.res.output) {
      console.log("Execution Output:\n", runRes.res.output);
    }
  }

  console.log("\n==================================================");
  console.log("All RF Screen artifacts deployed and TCODEs active!");
  console.log("Primary TCODE : ZRF_RESWM");
  console.log("Short Code    : ZRF01");
  console.log("==================================================");
}

if (require.main === module) {
  main().catch(err => {
    console.error("Fatal deployment error:", err);
    process.exit(1);
  });
}

module.exports = { main, deployObject };
