let Contract;
let signer;
let userAccounts;
const ContractAddress = "";
const ContractABI = [];
const useGoerli = false; 
const provider = GetProvier();

// Creating variables for reusable dom elements
const initialMessage = document.querySelector("#initial-message");
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
  if(useGoerli){
    provider.send("eth_requestAccounts", []).then(() =>{
      provider.listAccounts().then((accounts) => {
        LoadAccounts(accounts);
      });
    }).catch(()=>{
      ConnectingError();
    });
  }else{
    provider.listAccounts().then((accounts) =>{
      LoadAccounts(accounts);
    }).catch(()=>{
      ConnectingError();
    });
  }
}
  
function LoadAccounts(accounts){
  userAccounts = accounts;
  accounts.forEach(c => {
    var opt = document.createElement("option");
    opt.innerHTML = String(c);
    userAddressesSelector.appendChild(opt);
  });
  updatedSignerContract();
  initialMessage.style.display = "none";
  userAccountFooter.style.display = "block";
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
    0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff]);
    console.log("ENCRIPT");
    EncriptBlock(key, block);
    console.log(hexPrint(block));
    console.log("DECRIPT");
    DecriptBlock(key, block);
    console.log(hexPrint(block)); 
}

function DecriptBlock(key,block){
  AES_Init();
  key = AES_ExpandKey(key);
  AES_Decrypt(block, key);
  AES_Done();
}

function EncriptBlock(key, block){
  AES_Init();
  key = AES_ExpandKey(key);
  AES_Encrypt(block, key);
  AES_Done();
}

RunTest();

InitApplication();
