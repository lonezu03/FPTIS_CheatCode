export function cannotAffordSponsoredPortions(
  walletBalance: number,
  sponsoredCartTotal: number,
) {
  const availableFund = Math.max(0, walletBalance);
  return sponsoredCartTotal > availableFund;
}
