const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const accountAddr = "0x0000000000000000000000000000000000000000";

  const signer = ethers.provider.getSigner(accountAddr);

  const name = "MotoClub";
  const symbol = "MC";
  const decymalPlaces = 18;
  const curator = "0x0000000000000000000000000000000000000000";
  const proposalDeposit = 1000;

  const Token = await ethers.getContractFactory("Token", signer);
  const token = await Token.deploy(name, symbol, decymalPlaces);
  await token.deployed();

  console.log("Token address (contract): ", token.address);

  const DAO = await ethers.getContractFactory("DAO", signer);
  const dao = await DAO.deploy(curator, proposalDeposit, token.address);
  await dao.deployed();

  console.log("DAO address (contract): ", dao.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
