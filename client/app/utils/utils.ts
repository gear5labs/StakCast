export function formatAmount(
  rawAmount: string | bigint,
  decimals: number = 18,
  precision: number = 2
): string {
  const amount = typeof rawAmount === "bigint" ? rawAmount : BigInt(rawAmount);
  const factor = BigInt(10) ** BigInt(decimals);
  const displayFactor = BigInt(10) ** BigInt(precision);
  const whole = amount / factor;
  const remainder = amount % factor;
  const decimalPart = Number((remainder * displayFactor) / factor);
  const decimalStr = decimalPart.toString().padStart(precision, "0");
  return `${whole.toString()}.${decimalStr} STRK`;
}

export function normalizeWEI(
  rawAmount: string | bigint,
  decimals: number = 18
): string {
  const amount = typeof rawAmount === "bigint" ? rawAmount : BigInt(rawAmount);
  const factor = BigInt(10) ** BigInt(decimals);

  const whole = amount / factor;
  const fraction = amount % factor;


  const fractionStr = fraction.toString().padStart(decimals, "0");


  const trimmedFraction = fractionStr.replace(/0+$/, "");

  return trimmedFraction.length > 0
    ? `${whole.toString()}.${trimmedFraction}`
    : whole.toString();
}
