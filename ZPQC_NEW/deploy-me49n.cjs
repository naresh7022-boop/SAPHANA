const path = require("path");
const fs = require("fs");

// Resolve callAdtTool from scratch directory or local
const scratchCallTool = "/Users/naresh/.gemini/antigravity-ide/scratch/mcp-abap-adt/call-tool.cjs";
const { callAdtTool } = require(scratchCallTool);

async function deploy() {
  const localFile = path.resolve(__dirname, "zmm_r_me49n.prog.abap");
  const fallbackFile = "/Users/naresh/Documents/Github Development/SAPHANA/src/zmm_r_me49n.prog.abap";
  const filePath = fs.existsSync(localFile) ? localFile : fallbackFile;

  console.log(`Reading source from: ${filePath}`);
  const sourceCode = fs.readFileSync(filePath, "utf8");

  console.log("Uploading and activating ZMM_R_ME49N on SAP system DS4/220...");
  const res = await callAdtTool("UpdateProgram", {
    program_name: "ZMM_R_ME49N",
    source_code: sourceCode,
    activate: true
  });

  console.log("Result:", JSON.stringify(res, null, 2));
}

deploy().catch(err => {
  console.error("Deploy failed:", err);
  process.exit(1);
});
