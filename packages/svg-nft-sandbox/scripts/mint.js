const { deploy } = require("./deploy");

async function main() {
  const dynamicImageNFT = await deploy();
  const tokenId = 1; // トークンIDを指定してください
  const width = 500;
  const height = 500;
  const backgroundColor = "#000000";
  const text = "Hello, World!";
  const textColor = "#FFFFFF";
  const fontSize = 48;
  await dynamicImageNFT.mint(tokenId, width, height, backgroundColor, text, textColor, fontSize);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});