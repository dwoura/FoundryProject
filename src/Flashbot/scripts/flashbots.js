require("dotenv").config();

const { ethers } = require("ethers");
const { FlashbotsBundleProvider } = require("@flashbots/ethers-provider-bundle");

const INFRA_SEPOLIA = process.env.INFRA_SEPOLIA;
const TEST_PRIVATE_KEY_1 = process.env.TEST_PRIVATE_KEY_1;
const TEST_PRIVATE_KEY_2 = process.env.TEST_PRIVATE_KEY_2;
const TEST_PRIVATE_KEY_3 = process.env.TEST_PRIVATE_KEY_3;

async function createProvider() {
  const providers = [
    INFRA_SEPOLIA,
    "https://rpc.ankr.com/eth_sepolia",
    "https://rpc2.sepolia.org",
  ];

  for (const url of providers) {
    try {
      const provider = new ethers.JsonRpcProvider(url);
      await provider.getNetwork();
      console.log("Connected to provider:", url);
      return provider;
    } catch (error) {
      console.error("Failed to connect to provider:", url, error.message);
    }
  }
  throw new Error("Failed to connect to any provider");
}

async function main() {
  try {
    const provider = await createProvider();
    // dev wallet
    const walletDev = new ethers.Wallet(TEST_PRIVATE_KEY_1, provider);
    //  user wallet
    const wallet = new ethers.Wallet(TEST_PRIVATE_KEY_2, provider);
    const flashbotsProvider = await FlashbotsBundleProvider.create(
      provider,
      wallet, // user wallet
      "https://relay-sepolia.flashbots.net"
    );

    const openspaceNFTAddress = "0x0E033e49221D9B81bFa2beC2633d2cf6b51702A6";
    const abi = [
      {
        type: "function",
        name: "enablePresale",
        inputs: [],
        outputs: [],
        stateMutability: "nonpayable",
      },
      {
        type: "function",
        name: "presale",
        inputs: [
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        outputs: [],
        stateMutability: "payable",
      },
    ];

    const openspaceNFT = new ethers.Contract(openspaceNFTAddress, abi, wallet);

    const blockNumber = await provider.getBlockNumber();
    console.log(`Current block number: ${blockNumber}`);

    const walletAddress = await wallet.getAddress();
    console.log(`Wallet address: ${walletAddress}`);

    // 实际情况中是轮询监听启动，参与者发送抢预售tx
    const bundleTransactions = [
      {
        signer: walletDev, // 项目方钱包
        transaction: {
          to: openspaceNFTAddress,
          data: openspaceNFT.interface.encodeFunctionData("enablePresale"), // 项目方启动预售
          chainId: 11155111,
          gasLimit: 100000,
          maxFeePerGas: ethers.parseUnits("50", "gwei"), // 10->50 确保矿工打包
          maxPriorityFeePerGas: ethers.parseUnits("10", "gwei"), // 2->10
          type: 2, // EIP-1559 transaction
        },
      },
      {
        signer: wallet, // 参与者钱包
        transaction: {
          to: openspaceNFTAddress,
          data: openspaceNFT.interface.encodeFunctionData("presale",[2]), // 参与者参与预售，mint 2个
          chainId: 11155111,
          gasLimit: 500000, // 提高 gas 上限
          maxFeePerGas: ethers.parseUnits("50", "gwei"),
          maxPriorityFeePerGas: ethers.parseUnits("10", "gwei"),
          value: ethers.parseUnits("0.02", "ether"), // 注意携带 eth
          type: 2, // EIP-1559 transaction
        },
      },
    // 贿赂矿工
    //   {
    //     // 向矿工支付贿赂
    //     signer: wallet, // 付款人可以是任意账户
    //     transaction: {
    //       to: "0x0000000000000000000000000000000000000000", // 矿工的地址 (Coinbase 合约地址)
    //       value: ethers.parseUnits("0.01", "ether"), // 贿赂金额，通常为 0.01 ETH 或更多
    //       chainId: 11155111,
    //       gasLimit: 21000, // 普通转账的最低 gas
    //       maxFeePerGas: ethers.parseUnits("10", "gwei"),
    //       maxPriorityFeePerGas: ethers.parseUnits("2", "gwei"),
    //       type: 2, // EIP-1559 transaction
    //     },
    //   },
    ];

    // Helper function to convert BigNumbers to string
    const bigNumberToString = (key, value) =>
      typeof value === "bigint" ? value.toString() : value;

    console.log(
      "Bundle transactions:",
      JSON.stringify(bundleTransactions, bigNumberToString, 2)
    );

    // sign bundle tx
    const signedBundle = await flashbotsProvider.signBundle(bundleTransactions);

    // simulate bundle tx
    const simulation = await flashbotsProvider.simulate(
      signedBundle,
      blockNumber + 1
    );
    if ("error" in simulation) {
      console.error("Simulation error:", simulation.error);
    } else {
      console.log(
        "Simulation results:",
        JSON.stringify(simulation, bigNumberToString, 2)
      );
    }

    // send bundle tx when simulation.error == null
    const bundleResponse = await flashbotsProvider.sendBundle(
      bundleTransactions,
      blockNumber + 1
    );

    if ("error" in bundleResponse) {
      console.error("Error sending bundle:", bundleResponse.error);
      return;
    }

    console.log(
      "Bundle response:",
      JSON.stringify(bundleResponse, bigNumberToString, 2)
    );

    const bundleReceipt = await bundleResponse.wait();
    if (bundleReceipt === 1) {
      console.log("Bundle included in block");
    } else {
      console.log("Bundle not included");
    }

    const bundleStats = await flashbotsProvider.getBundleStats(
      bundleResponse.bundleHash,
      blockNumber + 1
    );
    console.log("Bundle stats:", JSON.stringify(bundleStats, bigNumberToString, 2));
  } catch (error) {
    console.error("Error during transaction processing:", error);
  }
}

main().catch((error) => {
  console.error("Main function error:", error);
  process.exit(1);
});


