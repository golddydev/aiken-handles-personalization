import { Network } from "@meshsdk/core";

function getNetworkId(network: Network): 0 | 1;
function getNetworkId(isMainnet: boolean): 0 | 1;
function getNetworkId(network: Network | boolean): 0 | 1 {
  if (typeof network === "boolean") {
    return network ? 1 : 0;
  }
  return network === "mainnet" ? 1 : 0;
}

export { getNetworkId };
