import { tool } from "@opencode-ai/plugin";
import { execSync } from "child_process";
import { extname } from "path";

export default tool({
  description:
    "Read PDF files and return their text content. Use this instead of the regular read tool when the file is a PDF.",
  args: {
    file: tool.schema.string().describe("Absolute path to the PDF file"),
  },
  async execute(args) {
    const ext = extname(args.file).toLowerCase();
    if (ext !== ".pdf") {
      return `Error: ${args.file} is not a PDF file`;
    }
    const output = execSync(`pdftotext "${args.file}" -`, {
      maxBuffer: 10 * 1024 * 1024,
    });
    return output.toString();
  },
});
