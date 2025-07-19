export interface MarketOption {
  name: string;
  odds: number;
}

export interface DummyMarketType {
  id: number;
  name: string;
  image: string;
  options: MarketOption[];
  totalRevenue: string;
  categories: string[];
  status: "active" | "inactive";
  startTime: number;
  endTime: number;
  createdBy: string;
}

export type BaseProps = {
  className?: string;
};

export interface MarketChoiceData {
  label: bigint | string;
  staked_amount: bigint | string;
}

export interface MarketChoices {
  0: MarketChoiceData;
  1: MarketChoiceData;
}

export interface CairoOption<T = unknown> {
  Some?: T;
  None?: boolean;
}

export interface Market {
  market_id: bigint | string | number;
  category: bigint | string;
  title: string;
  description: string;
  image_url: string;
  end_time: bigint;
  is_open: boolean;
  is_resolved: boolean;
  choices: MarketChoices;
  total_pool: bigint;
  total_shares_option_one: bigint;
  total_shares_option_two: bigint;

  winning_choice: CairoOption<number>;
}
