let Contract;
let signer;
let userAccounts;
let key;
const ContractAddress = "";
const ContractABI = [];
const useGoerli = false; 
const provider = GetProvier();

// Creating variables for reusable dom elements
const initialMessage = document.querySelector("#initial-message");
const greetingMessage = document.querySelector("#greeting-message");
const mainMenu = document.querySelector("#main-menu");
const userAccountFooter = document.querySelector("#user-account-footer");
const userAddressesSelector = document.querySelector("#user-account-address");

function updatedSignerContract(){
  signer = provider.getSigner(userAccountFooter.selectedIndex);
  Contract = new ethers.Contract(
    ContractAddress,
    ContractABI,
    signer
  );
}

function HandleContracError(response){
  response = String(response);
  alert("ERROR: Unknown error");
  console.log(response);
}

function RemoveAllChilds(element){
  while(element.lastChild){
    element.removeChild(element.lastChild);
  }
}

function ConnectingError(){
  msg_form =  initialMessage.querySelector(".initial-message-form");
  RemoveAllChilds(msg_form);
  var h = document.createElement("h1");
  h.innerHTML = ("Error :'(");
  var br = document.createElement("br");
  var p = document.createElement("p");
  p.innerHTML = ("Could not connect to your MetaMask Wallet.");
  msg_form.appendChild(h);
  msg_form.appendChild(br);
  msg_form.appendChild(p);
  throw Error("Could not connect to your MetaMask Wallet.");
}

function GetProvier(){
  if(useGoerli){
    return ((window.ethereum != null) ? 
      new ethers.providers.Web3Provider(window.ethereum) : ethers.providers.getDefaultProvider());
  }
  let ganacheURL = "http://127.0.0.1:7545";
  return new ethers.providers.JsonRpcProvider(ganacheURL);
}
  
async function InitApplication(){
  await LoadAccounts().catch(() =>{
    ConnectingError();
  });
  DisplayGreetingMessage();
}

async function RequestUserAccounts(){
  if(useGoerli){
    await provider.send("eth_requestAccounts", []);
  }
}

function DisplayGreetingMessage(){
  initialMessage.style.display = "none";
  greetingMessage.style.display = "block";
  mainMenu.style.display = "none";
  userAccountFooter.style.display = "none";
}

function DisplayMainMenu(){
  initialMessage.style.display = "none";
  greetingMessage.style.display = "none";
  mainMenu.style.display = "block";
  userAccountFooter.style.display = "block";
}

async function LoadAccounts(){
  await RequestUserAccounts();
  userAccounts = await provider.listAccounts().then((accounts) =>{
    return accounts;
  });
  userAccounts.forEach(c => {
    var opt = document.createElement("option");
    opt.innerHTML = String(c);
    userAddressesSelector.appendChild(opt);
  });
  updatedSignerContract();
}

function GenerateNewKey(){
  key = self.crypto.getRandomValues(new Uint8Array(16));
}

function EncryptWord(word){
  if(word.length >= 50){
    throw new RangeError("The word has more than 50 characters");
  }
  let block = new Uint8Array(64);
  let i;
  for(i = 0; i < word.length; i++){
    block[63 - i] = word.charCodeAt(i);
  }
  block[63 - 1] = 0;
  EncryptBlock(block, expandedKey);
  return block;
}

function DecryptWord(key, block){
  DecryptBlock(key, block);
  word = "";
  let i = 63;
  while((i >= 0) && (block[i] != 0)){
    word += String.fromCharCode(b[i]);
    i--;
  }
  return word; 
}

function RunTest(){
  /*
  //Test Key Expansion
  let key = new Uint8Array([ 
    0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
    0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c]);
  */
  let key = new Uint8Array([
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
    0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
 ])
  let block = new Uint16Array([
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff,
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff
  ]);
    console.log("Block: " + hexPrint(block));
    console.log("Key: " + hexPrint(key));
    console.log("ENCRIPT");
    EncryptBlock(key, block);
    console.log("Block: " + hexPrint(block));
    console.log("Key: " + hexPrint(key));
    console.log("DECRIPT");
    DecryptBlock(key, block);
    console.log("Block: " + hexPrint(block));
    console.log("Key: " + hexPrint(key));
}

function DecryptBlock(key,block){
  if(block.length%16 != 0){
    throw new Error('AES only works with 16 bytes (128bits) blocks of info.');
  }
  AES_Init();
  let expandedKey = AES_ExpandKey(key);
  for(let i = 0; i < Math.floor(block.length/16); i++){
    let b = block.slice(i*16, (i+1)*16);
    AES_Decrypt(b, expandedKey);
    for(let j = 0; j < 16; j++){
      block[i*16 + j] = b[j];
    }
  }  
  AES_Done();
}

function EncryptBlock(key, block){
  if(block.length%16 != 0){
    throw new Error('AES only works with 16 bytes (128bits) blocks of info.');
  }
  AES_Init();
  let expandedKey = AES_ExpandKey(key);
  for(let i = 0; i < Math.floor(block.length/16); i++){
    let b = block.slice(i*16, (i+1)*16);
    AES_Encrypt(b, expandedKey);
    for(let j = 0; j < 16; j++){
      block[i*16 + j] = b[j];
    }
  } 
  AES_Done();
}

//RunTest();

InitApplication();
