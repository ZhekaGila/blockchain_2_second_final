import { useState, useEffect } from "react";
import { ethers } from "ethers";
import "./App.css";

const AMM_ADDRESS = "0x32EEce76C2C2e8758584A83Ee2F522D4788feA0f";
const TOKEN0_ADDRESS = "0x6F6f570F45833E249e27022648a26F4076F48f78";
const TOKEN1_ADDRESS = "0xCA8c8688914e0F7096c920146cd0Ad85cD7Ae8b9";

const ITEMS_ADDRESS = "0x5FeaeBfB4439F3516c74939A9D04e95AFE82C4ae";
const CRAFTING_ADDRESS = "0x976fcd02f7C4773dd89C309fBF55D5923B4c98a1";

const GOVERNOR_ADDRESS = "0x8bCe54ff8aB45CB075b044AE117b8fD91F9351aB";
const ITEM_SHOP_ADDRESS = "0xA56F946D6398Dd7d9D4D9B337Cf9E0F68982ca5B";

const TOKEN_ADDRESS = TOKEN0_ADDRESS;

const RPC_URL = "http://127.0.0.1:8545";
const readProvider = new ethers.JsonRpcProvider(RPC_URL);

const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function symbol() view returns (string)",
  "function allowance(address owner,address spender) view returns (uint256)"
];

const AMM_ABI = [
  "function reserve0() view returns (uint256)",
  "function reserve1() view returns (uint256)",
  "function addLiquidity(uint256 amount0, uint256 amount1) returns (uint256)",
  "function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut) returns (uint256)",
  "function getAmountOut(address tokenIn, uint256 amountIn) view returns (uint256)"
];

const ITEMS_ABI = [
  "function balanceOf(address account, uint256 id) view returns (uint256)",
  "function setApprovalForAll(address operator, bool approved)",
  "function mint(address to, uint256 id, uint256 amount)"
];

const CRAFTING_ABI = [
  "function craftSword()",
  "function getRecipe() view returns (uint256,uint256,uint256)",
  "function setSwordRecipe(uint256 newWoodCost,uint256 newStoneCost,uint256 newIronCost)"
];

const GOVERNOR_ABI = [
  "function propose(address[] targets,uint256[] values,bytes[] calldatas,string description) returns (uint256)",
  "function castVote(uint256 proposalId,uint8 support) returns (uint256)",
  "function state(uint256 proposalId) view returns (uint8)",
  "function queue(address[] targets,uint256[] values,bytes[] calldatas,bytes32 descriptionHash) returns (uint256)",
  "function execute(address[] targets,uint256[] values,bytes[] calldatas,bytes32 descriptionHash) payable returns (uint256)",
  "event ProposalCreated(uint256 proposalId,address proposer,address[] targets,uint256[] values,string[] signatures,bytes[] calldatas,uint256 voteStart,uint256 voteEnd,string description)"
];

const GOV_TOKEN_ABI = [
  "function balanceOf(address account) view returns (uint256)",
  "function delegate(address delegatee)",
  "function getVotes(address account) view returns (uint256)",
  "function delegates(address account) view returns (address)"
];

const ITEM_SHOP_ABI = [
  "function buyWood(uint256 amount)",
  "function buyStone(uint256 amount)",
  "function buyIron(uint256 amount)"
];

function App() {
  const [account, setAccount] = useState("");

  const [reserve0, setReserve0] = useState("0");
  const [reserve1, setReserve1] = useState("0");

  const [status, setStatus] = useState("");

  const [wood, setWood] = useState("0");
  const [stone, setStone] = useState("0");
  const [iron, setIron] = useState("0");
  const [sword, setSword] = useState("0");

  const [gameBalance, setGameBalance] = useState("0");
  const [goldBalance, setGoldBalance] = useState("0");

  const [votes, setVotes] = useState("0");
  const [delegate, setDelegate] = useState("");
  const [proposalId, setProposalId] = useState("");
  const [proposalState, setProposalState] = useState("No proposal");
  const [proposalData, setProposalData] = useState(null);
  const [recipe, setRecipe] = useState("Not loaded");

  function stateName(id) {
    const states = [
      "Pending",
      "Active",
      "Canceled",
      "Defeated",
      "Succeeded",
      "Queued",
      "Expired",
      "Executed"
    ];

    return states[Number(id)] || "Unknown";
  }

  function getErrorMessage(err) {
    console.error(err);

    if (err?.shortMessage) return err.shortMessage;
    if (err?.reason) return err.reason;
    if (err?.info?.error?.message) return err.info.error.message;
    if (err?.message) return err.message;

    return "Unknown error";
  }

  async function getSignerAndAddress() {
    if (!window.ethereum) {
      throw new Error("MetaMask is not installed");
    }

    const provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);

    const signer = await provider.getSigner();
    const address = await signer.getAddress();

    return { provider, signer, address };
  }

  async function connectWallet() {
    try {
      const { address } = await getSignerAndAddress();

      setAccount(address);
      setStatus("Wallet connected");

      await refreshAll();
    } catch (err) {
      setStatus(`Connect failed: ${getErrorMessage(err)}`);
    }
  }

  async function loadReserves() {
    try {
      const amm = new ethers.Contract(AMM_ADDRESS, AMM_ABI, readProvider);

      const r0 = await amm.reserve0();
      const r1 = await amm.reserve1();

      setReserve0(ethers.formatEther(r0));
      setReserve1(ethers.formatEther(r1));
    } catch (err) {
      setStatus(`Load reserves failed: ${getErrorMessage(err)}`);
    }
  }

  async function loadTokenBalances() {
    try {
      const { address } = await getSignerAndAddress();

      const game = new ethers.Contract(TOKEN0_ADDRESS, ERC20_ABI, readProvider);
      const gold = new ethers.Contract(TOKEN1_ADDRESS, ERC20_ABI, readProvider);

      setGameBalance(ethers.formatEther(await game.balanceOf(address)));
      setGoldBalance(ethers.formatEther(await gold.balanceOf(address)));
    } catch (err) {
      setStatus(`Load balances failed: ${getErrorMessage(err)}`);
    }
  }

  async function approveTokens() {
    try {
      const { signer } = await getSignerAndAddress();

      const token0 = new ethers.Contract(TOKEN0_ADDRESS, ERC20_ABI, signer);
      const token1 = new ethers.Contract(TOKEN1_ADDRESS, ERC20_ABI, signer);

      setStatus("Approving GameToken...");
      await (await token0.approve(AMM_ADDRESS, ethers.parseEther("100000"))).wait();

      setStatus("Approving GoldToken...");
      await (await token1.approve(AMM_ADDRESS, ethers.parseEther("100000"))).wait();

      setStatus("Tokens approved");
    } catch (err) {
      setStatus(`Approve failed: ${getErrorMessage(err)}`);
    }
  }

  async function addLiquidity() {
    try {
      const { signer } = await getSignerAndAddress();

      const amm = new ethers.Contract(AMM_ADDRESS, AMM_ABI, signer);

      setStatus("Adding liquidity...");
      await (
        await amm.addLiquidity(
          ethers.parseEther("100"),
          ethers.parseEther("100")
        )
      ).wait();

      setStatus("Liquidity added");
      await loadReserves();
      await loadTokenBalances();
    } catch (err) {
      setStatus(`Add liquidity failed: ${getErrorMessage(err)}`);
    }
  }

  async function swapToken0ToToken1() {
    try {
      const { signer } = await getSignerAndAddress();

      const amm = new ethers.Contract(AMM_ADDRESS, AMM_ABI, signer);

      setStatus("Swapping GameToken to GoldToken...");
      await (
        await amm.swap(TOKEN0_ADDRESS, ethers.parseEther("10"), 0)
      ).wait();

      setStatus("Swap completed");
      await loadReserves();
      await loadTokenBalances();
    } catch (err) {
      setStatus(`Swap failed: ${getErrorMessage(err)}`);
    }
  }

  async function swapToken1ToToken0() {
    try {
      const { signer } = await getSignerAndAddress();

      const amm = new ethers.Contract(AMM_ADDRESS, AMM_ABI, signer);

      setStatus("Swapping GoldToken to GameToken...");
      await (
        await amm.swap(TOKEN1_ADDRESS, ethers.parseEther("10"), 0)
      ).wait();

      setStatus("Swap completed");
      await loadReserves();
      await loadTokenBalances();
    } catch (err) {
      setStatus(`Swap failed: ${getErrorMessage(err)}`);
    }
  }

  async function loadItems() {
    try {
      const { address } = await getSignerAndAddress();

      const items = new ethers.Contract(ITEMS_ADDRESS, ITEMS_ABI, readProvider);

      setWood((await items.balanceOf(address, 1)).toString());
      setStone((await items.balanceOf(address, 2)).toString());
      setIron((await items.balanceOf(address, 3)).toString());
      setSword((await items.balanceOf(address, 4)).toString());
    } catch (err) {
      setStatus(`Load items failed: ${getErrorMessage(err)}`);
    }
  }

  async function mintResources() {
    try {
      const { signer, address } = await getSignerAndAddress();

      const items = new ethers.Contract(ITEMS_ADDRESS, ITEMS_ABI, signer);

      setStatus("Minting wood...");
      let tx = await items.mint(address, 1, 10);
      await tx.wait();

      setStatus("Minting stone...");
      tx = await items.mint(address, 2, 10);
      await tx.wait();

      setStatus("Minting iron...");
      tx = await items.mint(address, 3, 10);
      await tx.wait();

      setStatus("Resources minted");
      await loadItems();
    } catch (err) {
      setStatus(`Mint failed: ${getErrorMessage(err)}`);
    }
  }

  async function approveCrafting() {
    try {
      const { signer } = await getSignerAndAddress();

      const items = new ethers.Contract(ITEMS_ADDRESS, ITEMS_ABI, signer);

      setStatus("Approving crafting contract...");
      await (await items.setApprovalForAll(CRAFTING_ADDRESS, true)).wait();

      setStatus("Crafting approved");
    } catch (err) {
      setStatus(`Crafting approve failed: ${getErrorMessage(err)}`);
    }
  }

  async function craftSword() {
    try {
      const { signer } = await getSignerAndAddress();

      const crafting = new ethers.Contract(CRAFTING_ADDRESS, CRAFTING_ABI, signer);

      setStatus("Crafting sword...");
      await (await crafting.craftSword()).wait();

      setStatus("Sword crafted");
      await loadItems();
    } catch (err) {
      setStatus(`Craft sword failed: ${getErrorMessage(err)}`);
    }
  }

  async function approveGoldForShop() {
    try {
      const { signer } = await getSignerAndAddress();

      const gold = new ethers.Contract(TOKEN1_ADDRESS, ERC20_ABI, signer);

      setStatus("Approving GoldToken for shop...");
      await (
        await gold.approve(ITEM_SHOP_ADDRESS, ethers.parseEther("100000"))
      ).wait();

      setStatus("Gold approved for shop");
    } catch (err) {
      setStatus(`Shop approve failed: ${getErrorMessage(err)}`);
    }
  }

  async function buyWood() {
    try {
      const { signer } = await getSignerAndAddress();
      const shop = new ethers.Contract(ITEM_SHOP_ADDRESS, ITEM_SHOP_ABI, signer);

      setStatus("Buying wood...");
      await (await shop.buyWood(3)).wait();

      setStatus("Wood bought");
      await loadItems();
      await loadTokenBalances();
    } catch (err) {
      setStatus(`Buy wood failed: ${getErrorMessage(err)}`);
    }
  }

  async function buyStone() {
    try {
      const { signer } = await getSignerAndAddress();
      const shop = new ethers.Contract(ITEM_SHOP_ADDRESS, ITEM_SHOP_ABI, signer);

      setStatus("Buying stone...");
      await (await shop.buyStone(2)).wait();

      setStatus("Stone bought");
      await loadItems();
      await loadTokenBalances();
    } catch (err) {
      setStatus(`Buy stone failed: ${getErrorMessage(err)}`);
    }
  }

  async function buyIron() {
    try {
      const { signer } = await getSignerAndAddress();
      const shop = new ethers.Contract(ITEM_SHOP_ADDRESS, ITEM_SHOP_ABI, signer);

      setStatus("Buying iron...");
      await (await shop.buyIron(1)).wait();

      setStatus("Iron bought");
      await loadItems();
      await loadTokenBalances();
    } catch (err) {
      setStatus(`Buy iron failed: ${getErrorMessage(err)}`);
    }
  }

  async function loadGovernance() {
    try {
      const { address } = await getSignerAndAddress();

      const token = new ethers.Contract(TOKEN_ADDRESS, GOV_TOKEN_ABI, readProvider);

      const currentVotes = await token.getVotes(address);
      const currentDelegate = await token.delegates(address);

      setVotes(ethers.formatEther(currentVotes));
      setDelegate(currentDelegate);

      if (proposalId) {
        const governor = new ethers.Contract(
          GOVERNOR_ADDRESS,
          GOVERNOR_ABI,
          readProvider
        );

        const state = await governor.state(proposalId);
        setProposalState(stateName(state));
      }

      setStatus("Governance loaded");
    } catch (err) {
      setStatus(`Load governance failed: ${getErrorMessage(err)}`);
    }
  }

  async function delegateVotes() {
    try {
      const { signer, address } = await getSignerAndAddress();

      const token = new ethers.Contract(TOKEN_ADDRESS, GOV_TOKEN_ABI, signer);

      setStatus("Delegating votes to yourself...");
      await (await token.delegate(address)).wait();

      setStatus("Votes delegated. Mine 1-2 blocks before creating proposal.");
      await loadGovernance();
    } catch (err) {
      setStatus(`Delegate failed: ${getErrorMessage(err)}`);
    }
  }

  async function createProposal() {
    try {
      const { signer } = await getSignerAndAddress();

      const governor = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, signer);

      const iface = new ethers.Interface([
        "function setSwordRecipe(uint256,uint256,uint256)"
      ]);

      const calldata = iface.encodeFunctionData("setSwordRecipe", [1, 1, 1]);

      const targets = [CRAFTING_ADDRESS];
      const values = [0];
      const calldatas = [calldata];
      const description = "Change sword recipe to 1-1-1";

      setStatus("Creating recipe proposal...");

      const tx = await governor.propose(
        targets,
        values,
        calldatas,
        description
      );

      const receipt = await tx.wait();

      const parsedEvent = receipt.logs
        .map((log) => {
          try {
            return governor.interface.parseLog(log);
          } catch {
            return null;
          }
        })
        .find((event) => event && event.name === "ProposalCreated");

      if (!parsedEvent) {
        setStatus("Proposal event not found");
        return;
      }

      const id = parsedEvent.args.proposalId.toString();

      const data = {
        proposalId: id,
        targets,
        values,
        calldatas,
        description
      };

      setProposalId(id);
      setProposalData(data);
      setProposalState("Pending");

      localStorage.setItem("proposalData", JSON.stringify(data));

      setStatus("Recipe proposal created. Mine 2 blocks, then vote.");
    } catch (err) {
      setStatus(`Create proposal failed: ${getErrorMessage(err)}`);
    }
  }

  async function voteForProposal() {
    try {
      if (!proposalId) {
        setStatus("No proposal ID");
        return;
      }

      const { signer } = await getSignerAndAddress();

      const governor = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, signer);

      setStatus("Voting FOR...");
      await (await governor.castVote(proposalId, 1)).wait();

      setStatus("Vote submitted. Mine 25 blocks, then refresh.");
      await loadGovernance();
    } catch (err) {
      setStatus(`Vote failed: ${getErrorMessage(err)}`);
    }
  }

  async function queueProposal() {
    try {
      if (!proposalData) {
        setStatus("No proposal data. Create proposal again or reload saved proposal.");
        return;
      }

      const { signer } = await getSignerAndAddress();

      const governor = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, signer);

      setStatus("Queueing proposal...");
      await (
        await governor.queue(
          proposalData.targets,
          proposalData.values,
          proposalData.calldatas,
          ethers.id(proposalData.description)
        )
      ).wait();

      setStatus("Proposal queued. Increase time 180s, mine 1 block, then execute.");
      await loadGovernance();
    } catch (err) {
      setStatus(`Queue failed: ${getErrorMessage(err)}`);
    }
  }

  async function executeProposal() {
    try {
      if (!proposalData) {
        setStatus("No proposal data. Create proposal again or reload saved proposal.");
        return;
      }

      const { signer } = await getSignerAndAddress();

      const governor = new ethers.Contract(GOVERNOR_ADDRESS, GOVERNOR_ABI, signer);

      setStatus("Executing proposal...");
      await (
        await governor.execute(
          proposalData.targets,
          proposalData.values,
          proposalData.calldatas,
          ethers.id(proposalData.description)
        )
      ).wait();

      setStatus("Proposal executed");
      await loadGovernance();
      await loadRecipe();
    } catch (err) {
      setStatus(`Execute failed: ${getErrorMessage(err)}`);
    }
  }

  async function loadRecipe() {
    try {
      const crafting = new ethers.Contract(
        CRAFTING_ADDRESS,
        CRAFTING_ABI,
        readProvider
      );

      const [woodCost, stoneCost, ironCost] = await crafting.getRecipe();

      setRecipe(`${woodCost} wood, ${stoneCost} stone, ${ironCost} iron`);
      setStatus("Recipe loaded");
    } catch (err) {
      setStatus(`Load recipe failed: ${getErrorMessage(err)}`);
    }
  }

  async function mineBlocks(count) {
    try {
      setStatus(`Mining ${count} blocks...`);
      await readProvider.send("anvil_mine", [ethers.toBeHex(count)]);
      setStatus(`${count} blocks mined`);
      await loadGovernance();
    } catch (err) {
      setStatus(`Mine failed: ${getErrorMessage(err)}`);
    }
  }

  async function increaseTime180() {
    try {
      setStatus("Increasing time by 180 seconds...");
      await readProvider.send("evm_increaseTime", [180]);
      await readProvider.send("anvil_mine", ["0x1"]);
      setStatus("Time increased and 1 block mined");
      await loadGovernance();
    } catch (err) {
      setStatus(`Increase time failed: ${getErrorMessage(err)}`);
    }
  }

  async function reloadSavedProposal() {
    try {
      const saved = localStorage.getItem("proposalData");

      if (!saved) {
        setStatus("No saved proposal");
        return;
      }

      const data = JSON.parse(saved);

      setProposalData(data);
      setProposalId(data.proposalId);

      setStatus("Saved proposal loaded");
      await loadGovernance();
    } catch (err) {
      setStatus(`Reload saved proposal failed: ${getErrorMessage(err)}`);
    }
  }

  async function refreshAll() {
    await loadReserves();
    await loadTokenBalances();
    await loadItems();
    await loadGovernance();
    await loadRecipe();
  }

  useEffect(() => {
    loadReserves();

    const saved = localStorage.getItem("proposalData");

    if (saved) {
      const data = JSON.parse(saved);
      setProposalData(data);
      setProposalId(data.proposalId);
    }
  }, []);

  const price0 =
    Number(reserve0) === 0 ? 0 : Number(reserve1) / Number(reserve0);

  const price1 =
    Number(reserve1) === 0 ? 0 : Number(reserve0) / Number(reserve1);

  const shortAccount = account
    ? `${account.slice(0, 6)}...${account.slice(-4)}`
    : "Not connected";

  const formatNumber = (value) => {
    const number = Number(value);
    if (!Number.isFinite(number)) return value;
    return number.toLocaleString(undefined, { maximumFractionDigits: 4 });
  };

  return (
    <div className="app">
      <section className="hero">
        <div className="hero__content">
          <div className="eyebrow">GameFi DeFi Dashboard</div>
          <h1>GameFi AMM, Crafting & Governance</h1>
          <p className="hero__text">
            Manage tokens, trade through AMM, buy resources, craft swords and control
            the recipe through DAO voting.
          </p>

          <div className="hero__actions">
            <button className="primary" onClick={connectWallet}>
              {account ? "Wallet Connected" : "Connect MetaMask"}
            </button>
            <button className="secondary" onClick={refreshAll}>
              Refresh All
            </button>
          </div>
        </div>

        <div className="wallet-card">
          <span>Connected account</span>
          <strong>{shortAccount}</strong>
          <p>{status || "Ready to connect with local Anvil network"}</p>
        </div>
      </section>

      <section className="stats-grid">
        <div className="stat-card">
          <span>GameToken</span>
          <strong>{formatNumber(gameBalance)}</strong>
          <p>Main game and governance token</p>
        </div>
        <div className="stat-card">
          <span>GoldToken</span>
          <strong>{formatNumber(goldBalance)}</strong>
          <p>Currency for shop and swaps</p>
        </div>
        <div className="stat-card">
          <span>Voting Power</span>
          <strong>{formatNumber(votes)}</strong>
          <p>{delegate ? `Delegated to ${delegate.slice(0, 6)}...${delegate.slice(-4)}` : "Not delegated yet"}</p>
        </div>
        <div className="stat-card">
          <span>Crafted Swords</span>
          <strong>{sword}</strong>
          <p>Current recipe: {recipe}</p>
        </div>
      </section>

      <main className="dashboard">
        <section className="panel wide">
          <div className="panel__header">
            <div>
              <span className="section-kicker">AMM Pool</span>
              <h2>Liquidity & Swap</h2>
            </div>
            <div className="badge">Live price</div>
          </div>

          <div className="pool-grid">
            <div className="token-tile">
              <span>GameToken reserve</span>
              <strong>{formatNumber(reserve0)}</strong>
            </div>
            <div className="token-tile">
              <span>GoldToken reserve</span>
              <strong>{formatNumber(reserve1)}</strong>
            </div>
            <div className="token-tile">
              <span>1 GAME</span>
              <strong>{formatNumber(price0)} GOLD</strong>
            </div>
            <div className="token-tile">
              <span>1 GOLD</span>
              <strong>{formatNumber(price1)} GAME</strong>
            </div>
          </div>

          <div className="button-row">
            <button onClick={approveTokens}>Approve Tokens</button>
            <button onClick={addLiquidity}>Add 100 / 100 Liquidity</button>
            <button onClick={swapToken0ToToken1}>Swap 10 GAME → GOLD</button>
            <button onClick={swapToken1ToToken0}>Swap 10 GOLD → GAME</button>
          </div>
        </section>

        <section className="panel">
          <div className="panel__header">
            <div>
              <span className="section-kicker">Item Shop</span>
              <h2>Buy Resources</h2>
            </div>
            <div className="badge gold">Gold</div>
          </div>

          <div className="shop-list">
            <div className="shop-item">
              <span className="item-icon">🪵</span>
              <div>
                <strong>Wood</strong>
                <p>Buy 3 pieces</p>
              </div>
              <button onClick={buyWood}>Buy</button>
            </div>
            <div className="shop-item">
              <span className="item-icon">🪨</span>
              <div>
                <strong>Stone</strong>
                <p>Buy 2 pieces</p>
              </div>
              <button onClick={buyStone}>Buy</button>
            </div>
            <div className="shop-item">
              <span className="item-icon">⛓️</span>
              <div>
                <strong>Iron</strong>
                <p>Buy 1 piece</p>
              </div>
              <button onClick={buyIron}>Buy</button>
            </div>
          </div>

          <button className="full secondary" onClick={approveGoldForShop}>
            Approve Gold for Shop
          </button>
        </section>

        <section className="panel">
          <div className="panel__header">
            <div>
              <span className="section-kicker">Crafting</span>
              <h2>Inventory</h2>
            </div>
            <div className="badge purple">NFT Items</div>
          </div>

          <div className="inventory-grid">
            <div><span>🪵</span><strong>{wood}</strong><p>Wood</p></div>
            <div><span>🪨</span><strong>{stone}</strong><p>Stone</p></div>
            <div><span>⛓️</span><strong>{iron}</strong><p>Iron</p></div>
            <div><span>⚔️</span><strong>{sword}</strong><p>Sword</p></div>
          </div>

          <div className="recipe-box">
            <span>Current sword recipe</span>
            <strong>{recipe}</strong>
          </div>

          <div className="button-row vertical">
            <button onClick={loadItems}>Load Items</button>
            <button onClick={mintResources}>Mint Resources</button>
            <button onClick={approveCrafting}>Approve Crafting</button>
            <button className="primary" onClick={craftSword}>Craft Sword</button>
            <button onClick={loadRecipe}>Load Recipe</button>
          </div>
        </section>

        <section className="panel wide governance">
          <div className="panel__header">
            <div>
              <span className="section-kicker">DAO Governance</span>
              <h2>Change Sword Recipe</h2>
            </div>
            <div className="badge">{proposalState}</div>
          </div>

          <div className="governance-grid">
            <div>
              <span>Proposal ID</span>
              <strong>{proposalId || "None"}</strong>
            </div>
            <div>
              <span>Proposal state</span>
              <strong>{proposalState}</strong>
            </div>
            <div>
              <span>Voting power</span>
              <strong>{formatNumber(votes)}</strong>
            </div>
          </div>

          <div className="timeline">
            <span>1 Delegate</span>
            <span>2 Mine</span>
            <span>3 Propose</span>
            <span>4 Vote</span>
            <span>5 Queue</span>
            <span>6 Execute</span>
          </div>

          <div className="button-row">
            <button onClick={loadGovernance}>Load Governance</button>
            <button onClick={delegateVotes}>Delegate Votes</button>
            <button onClick={() => mineBlocks(2)}>Mine 2 Blocks</button>
            <button onClick={createProposal}>Create Proposal</button>
            <button className="primary" onClick={voteForProposal}>Vote FOR</button>
            <button onClick={() => mineBlocks(25)}>Mine 25 Blocks</button>
            <button onClick={queueProposal}>Queue Proposal</button>
            <button onClick={increaseTime180}>Increase Time 180s</button>
            <button onClick={executeProposal}>Execute</button>
            <button onClick={reloadSavedProposal}>Reload Saved</button>
          </div>

          <p className="hint">
            Correct order: Delegate → Mine 2 → Create Proposal → Mine 2 → Vote FOR
            → Mine 25 → Queue → Increase Time → Execute → Load Recipe.
          </p>
        </section>
      </main>
    </div>
  );
}

export default App;