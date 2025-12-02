i wanted to make a smart contract project which when interacted from the frontend(that i will add in the future) have a marketplace contract and a merchants helper contract. thing was i didnt want the marketplace to inherit from the merchants contract exposing him.
for this the only scheme left in my mind was using the delegatecall calling the merchants helper contract making it use the marketplaces storage. the result was this low level evm assembly anarchy

🛠 Architecture Overview
EOA (User)  
  │
  ▼
Marketplace (storage + safe user functions)
  │
  ▼ delegatecall
Backend (logic module, no storage)


Marketplace: central hub, holds all data, handles ETH and balances.

Backend: implements core functionality, executed in marketplace context.
