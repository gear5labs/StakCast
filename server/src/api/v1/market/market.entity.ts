import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum MarketType {
  GENERAL = 'general',
  CRYPTO = 'crypto',
  SPORTS = 'sports',
  BUSINESS = 'business',
}

export enum ChoiceIndex {
  CHOICE_0 = 'CHOICE_0',
  CHOICE_1 = 'CHOICE_1',
}

@Entity({ name: 'markets' })
export class Market {
  @PrimaryColumn({ type: 'varchar', length: 255, name: 'market_id' })
  id!: string;

  @Column('varchar')
  title!: string;

  @Column('varchar')
  description!: string;

  @Column({
    type: 'enum',
    enum: MarketType,
    default: MarketType.GENERAL,
  })
  marketType!: MarketType;

  @Column('varchar')
  category!: string;

  @Column('varchar')
  imageUrl!: string;

  @Column('bigint')
  endTime!: string;

  @Column('boolean', { default: false })
  isResolved!: boolean;

  @Column('boolean', { default: true })
  isOpen!: boolean;

  @Column({
    type: 'enum',
    enum: ChoiceIndex,
    nullable: true,
  })
  winningChoice!: ChoiceIndex | null;

  @Column('decimal', {
    precision: 78,
    scale: 0,
    default: '0',
  })
  totalPool!: string;

  @Column('varchar', { length: 256 })
  creator!: string;

  @CreateDateColumn({ type: 'timestamp' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamp' })
  updatedAt!: Date;

  @Column('varchar')
  choice0Label!: string;

  @Column('decimal', {
    precision: 78,
    scale: 0,
    default: '0',
  })
  choice0Staked!: string;

  @Column('varchar')
  choice1Label!: string;

  @Column('decimal', {
    precision: 78,
    scale: 0,
    default: '0',
  })
  choice1Staked!: string;

  @Column('int', { nullable: true })
  comparisonType!: number | null;

  @Column('varchar', { nullable: true }) // <-- Fixed here
  assetKey!: string | null;

  @Column('bigint', { nullable: true })
  targetValue!: string | null;

  @Column('bigint', { nullable: true })
  eventId!: string | null;

  @Column('boolean', { nullable: true })
  teamFlag!: boolean | null;
}