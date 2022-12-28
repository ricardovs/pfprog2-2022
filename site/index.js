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

InitApplication();
