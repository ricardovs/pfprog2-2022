window.Oracle;
window.Factory;
window.Token;
window.Game;

window.signer;
window.userAccounts;
window.userAddress;
window.key;

window.oracleAddress = "";
window.factoryAddress = "";
window.gameAddress = "";

import { oracleABI, factoryABI, gameABI} from './contractsABI.js';
import {AES_Init, AES_ExpandKey, AES_Encrypt, AES_Decrypt, AES_Done} from './jsaes.js';
import {hexPrint} from './jsaes.js';

await fetch("../json/WordIds.json")
.then(response => {
   return response.json();
})
.then(jsondata => window.WordIds = jsondata);

window.BigNumber = window.ethers.BigNumber;

window.useGanache = true; 
window.provider = GetProvier();

// Creating variables for reusable dom elements
window.initialMessage = document.querySelector("#initial-message");
window.greetingMessage = document.querySelector("#greeting-message");
window.mainMenu = document.querySelector("#main-menu");
window.userAccountFooter = document.querySelector("#user-account-footer");
window.userAddressesSelector = document.querySelector("#user-account-address");
window.gameDisplayMenu = document.querySelector("#game-display-menu");
window.getTokenMenu = document.querySelector("#get-tokens-menu");
window.newGamenMenu = document.querySelector("#new-game-display-menu");

window.updateContracts = (() => {
  updateOracleContract();
  updateFactoryContract();
  updateGameContract();
});

function updateOracleContract(){
  if(window.oracleAddress == ""){
    return;
  }
  window.Oracle = new ethers.Contract(
    window.oracleAddress,
    oracleABI,
    window.signer
  );
  console.log("Updated Oracle Contract");
}

function updateFactoryContract(){
  if(window.factoryAddress == ""){
    return;
  }
  window.Factory = new ethers.Contract(
    window.factoryAddress,
    factoryABI,
    window.signer
  );
  console.log("Updated Factory Contract");
}

function updateGameContract() {
  if(window.gameAddress == ""){
    return;
  }
  window.Game = new ethers.Contract(
    window.gameAddress,
    gameABI,
    window.signer
  );
  console.log("Updated Game Contract");
}

function updatedSignerContract(){
  let index = window.userAccountFooter.selectedIndex;
  let address = window.userAccounts[index];
  window.signer = window.provider.getSigner(index);
  window.userAddress =  address;
  window.updateContracts();
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
  let msg_form =  window.initialMessage.querySelector(".initial-message-form");
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
  if(!window.useGanache){
    return ((window.ethereum != null) ? 
      new ethers.providers.Web3Provider(window.ethereum) : ethers.providers.getDefaultProvider());
  }
  let ganacheURL = "http://127.0.0.1:7545";
  return new ethers.providers.JsonRpcProvider(ganacheURL);
}
  
async function InitApplication(){
  await LoadAccounts().catch(() =>{
    if(typeof window.userAccounts == 'undefined'){
      ConnectingError();
    }
  });
  DisplayGreetingMessage();
}

async function RequestUserAccounts(){
  if(!window.useGanache){
    await window.provider.send("eth_requestAccounts", []);
  }
}

function DisplayGreetingMessage(){
  window.initialMessage.style.display = "none";
  window.greetingMessage.style.display = "block";
  window.mainMenu.style.display = "none";
  window.userAccountFooter.style.display = "none";
  window.gameDisplayMenu.style.display = "none";
  window.getTokenMenu.style.display = "none";
  window.newGamenMenu.style.display = "none";
}

function DisplayMainMenu(){
  window.initialMessage.style.display = "none";
  window.greetingMessage.style.display = "none";
  window.mainMenu.style.display = "block";
  window.userAccountFooter.style.display = "block";
  window.gameDisplayMenu.style.display = "none";
  window.getTokenMenu.style.display = "none";
  window.newGamenMenu.style.display = "none";
}

function DisplayGetTokenMenu(){
  window.initialMessage.style.display = "none";
  window.greetingMessage.style.display = "none";
  window.mainMenu.style.display = "none";
  window.userAccountFooter.style.display = "block";
  window.gameDisplayMenu.style.display = "none";
  window.getTokenMenu.style.display = "block";
  window.newGamenMenu.style.display = "none";
}

function DisplayGameMenu(){
  window.initialMessage.style.display = "none";
  window.greetingMessage.style.display = "none";
  window.mainMenu.style.display = "none";
  window.userAccountFooter.style.display = "block";
  window.gameDisplayMenu.style.display = "block";
  window.getTokenMenu.style.display = "none";
  window.newGamenMenu.style.display = "none";
}

function DisplayCreateGameMenu(){
  window.initialMessage.style.display = "none";
  window.greetingMessage.style.display = "none";
  window.mainMenu.style.display = "none";
  window.userAccountFooter.style.display = "block";
  window.gameDisplayMenu.style.display = "none";
  window.getTokenMenu.style.display = "none";
  window.newGamenMenu.style.display = "block";
}

function GetWordIndex(word){
  let index = 1;
  while(typeof WordIds[index] != 'undefined'){
    if(word.toLowerCase() == WordIds[index].toLowerCase()){
      return index;
    }
    index++;
  }
  return -1;
}

window.GetWordIndex = GetWordIndex;

function UpdateNewGameSubmit(){
  let word = document.querySelector("input#secret-word").value;
  let index = GetWordIndex(word);
  if(index > 0){
    document.querySelector("#new-game-button").disabled = false;
    return index;
  }else{
    document.querySelector("#new-game-button").disabled = true;
    return -1;
  }
}

document.querySelector("#get-token-menu-button")
  .addEventListener("click", DisplayGetTokenMenu);

document.querySelector("#game-list-button")
  .addEventListener("click", DisplayGameMenu);

document.querySelector("#create-game-button")
  .addEventListener("click", DisplayCreateGameMenu);

document.querySelectorAll('.display-greeting-button')
  .forEach((btn) =>{
    btn.addEventListener("click", DisplayGreetingMessage);
  });

document.querySelector("#user-account-address")
  .addEventListener("change", updatedSignerContract);

document.querySelectorAll('.back-to-main-menu').forEach((btn)=>{
  btn.addEventListener("click", DisplayMainMenu);
});

document.querySelector("#btn-get-tokens")
  .addEventListener("click", GetTokensRequest);

["change", "keypress", "paste", "input"].forEach((event) => {
  document.querySelector("#donation-value")
    .addEventListener(event, UpdateTokenToReceive);
  document.querySelector("#secret-word")
    .addEventListener(event, UpdateNewGameSubmit);
});

document.querySelector("#donation-unit")
  .addEventListener("change", UpdateTokenToReceive);

document.querySelector("#new-game-button")
  .addEventListener("click", CreateNewGame);

  document.querySelector("#reclaim-button")
    .addEventListener("click", ReclaimOwner)

async function LoadAccounts(){
  await RequestUserAccounts();
  window.userAccounts = await window.provider.listAccounts().then((accounts) =>{
    return accounts;
  });
  window.userAccounts.forEach(c => {
    var opt = document.createElement("option");
    opt.innerHTML = String(c);
    window.userAddressesSelector.appendChild(opt);
  });
  updatedSignerContract();
}

async function CreateNewGame(){
  let word = document.querySelector("input#secret-word").value;
  let index = GetWordIndex(word);
  if(index <= 0){
    alert("Could not create new game! Check your secret word.");
    return;
  }
  GenerateNewKey();
  let block = EncryptWord(word.toLowerCase());
  console.log({"block":block, "key":key})
  updateFactoryContract();
  console.log(block)
  window.gameAddress = await window.Factory.newGame([
    block[0],block[1],block[2],block[3],block[4],block[5],block[6],block[7],
    block[8],block[9],block[10],block[11],block[12],block[13],block[14],block[15],
    block[16],block[17],block[18],block[19],block[20],block[21],block[22],block[23],
    block[24],block[25],block[26],block[27],block[28],block[29],block[30],block[31],
    block[32],block[33],block[34],block[35],block[36],block[37],block[38],block[39],
    block[40],block[41],block[42],block[43],block[44],block[45],block[46],block[47],
    block[48],block[49],block[50],block[51],block[52],block[53],block[54],block[55],
    block[56],block[57],block[58],block[59],block[60],block[61],block[62],block[63]
  ]
  );
  console.log({"block":block, "key":key, "game":gameAddress});
  alert("New Game at : " + String(gameAddress));
}

function GenerateNewKey(){
  window.key = self.crypto.getRandomValues(new Uint8Array(32));
}


function ReclaimOwner(){
  let key = GetReclaimKey();
  console.log(key);
}
function GetReclaimKey(){
  let text = document.querySelector("#reclaim-key").value;
  let numbers = text.match(/([0-9]+)/mg);
  if((typeof numbers == "undefined")|| (numbers == null)){
    throw Error("Invalid key");
  }
  console.log(numbers);
  if(numbers.length != 32){
    throw Error("Not valid key size");
  }
  let array = new Uint8Array(32);
  for (let i = 0; i < 32; i++){
    array[i] = Number.parseInt(numbers[i]);
  }
  return array;
}


function EncryptWord(word){
  if(word.length >= 50){
    throw new RangeError("The word has more than 50 characters");
  }
  let block = ethers.utils.randomBytes(64);
  let i;
  for(i = 0; i < word.length; i++){
    block[63 - i] = word.charCodeAt(i);
  }
  block[63 - 1] = 0;
  block = EncryptBlock(key, block);
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

function ReadDonationUnit(){
  let unity = document.querySelector("#donation-unit").value;
  if(unity == "Wei"){
    return 0;
  }
  if(unity == "Gwei"){
    return 9;
  }
  if(unity == "Finney"){
    return 15;
  }
  if(unity == "Ether"){
    return 18;
  }
  throw Error("Unity not reconized.");
}

function ReadAmountDonation(){
  let amount = document.querySelector("#donation-value").value;
  let dotIndex = amount.indexOf('.');
  let zerosToAdd = ReadDonationUnit();
  if(dotIndex == -1){
    for(let i = 0; i < zerosToAdd; i++){
      amount += "0";
    }
  }else{
    let a = amount.slice(0,dotIndex);
    let b = amount.slice(dotIndex+1, dotIndex+1+zerosToAdd);
    amount = a + b;
    for(let i = 0; i < zerosToAdd-b.length; i++){
      amount += "0";
    }
  }
  while((amount.charAt(0)=="0") && (amount.length > 1)){
    amount = amount.slice(1,amount.length);
  }
  return amount;
}

function CalculateTokensToReceive(){
  let amount = ReadAmountDonation();
  let addZeros = 3;
  for(let i=0; i < addZeros; i++){
    amount += "0";
  }
  while((amount.charAt(0)=="0") && (amount.length > 1)){
    amount = amount.slice(1,amount.length);
  }
  return amount;
}

function UpdateTokenToReceive(){
  console.log("Update Receive")
  let amount = CalculateTokensToReceive();
  let input = document.querySelector("#input-token-to-receive")
  input.value = amount;
  input.max  = amount;
  input.ariaReadOnly = false;
}

async function balanceOf(account){
  return await Factory.balanceOf(account);
}

async function balanceOfSelf(){
  return await balanceOf(signer.getAddress());
}
async function GetTokensRequest(){
  let amount = ReadAmountDonation();
  let token = CalculateTokensToReceive();
  console.log(balanceOfSelf());
  await Factory.getTokens(BigNumber.from(token), {value:BigNumber.from(amount)});
  console.log(balanceOfSelf());
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
  return block;
}

//RunTest();

InitApplication();

