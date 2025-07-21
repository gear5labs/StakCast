import { container } from 'tsyringe';
import UserRepository from '../User/user.repository';
import MarketRepository from './buyshares.repository';
import UserSharesRepository from './userShares.repository';

export const buySharesService = async (userId: string, marketId: string, amount: number) => {
  // Check if user exists
  const userRepository = container.resolve(UserRepository);
  const user = await userRepository.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

  // Check if market exists
  const marketRepository = container.resolve(MarketRepository);
  const market = await marketRepository.findById(marketId);
  if (!market) {
    throw new Error('Market not found');
  }

  // Validate amount
  if (!amount || typeof amount !== 'number' || amount <= 0) {
    throw new Error('Invalid amount');
  }

  // Deduct funds
  if (user.balance < amount) {
    throw new Error('Insufficient balance');
  }

  user.balance -= amount;
  await userRepository.updateUser(userId, { balance: user.balance });

  // Update user's shares
  const userSharesRepository = container.resolve(UserSharesRepository);
  let userShares = await userSharesRepository.findByUserAndMarket(user, market);
  if (userShares) {
    userShares.shares += amount;
  } else {
    userShares = userSharesRepository.create({ user, market, shares: amount });
  }
  await userSharesRepository.save(userShares);

  return {
    userId,
    marketId,
    amount,
    newBalance: user.balance,
    totalShares: userShares.shares,
    status: 'Shares purchased successfully'
  };
};
