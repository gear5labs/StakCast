export function formatAmount(
  rawAmount: string | bigint,
  decimals: number = 16,
  precision: number = 2
): string {
  const amount = typeof rawAmount === "bigint" ? rawAmount : BigInt(rawAmount);
  const factor = BigInt(10) ** BigInt(decimals);
  const displayFactor = BigInt(10) ** BigInt(precision);

  const whole = amount / factor;
  const remainder = amount % factor;

  const decimalPart = Number((remainder * displayFactor) / factor);
  const decimalStr = decimalPart.toString().padStart(precision, "0");

  return `${whole.toString()}.${decimalStr}SK`;
}
