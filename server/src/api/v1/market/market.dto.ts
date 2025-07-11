import Joi from 'joi';

export const getMarketsSchema = Joi.object({
  status: Joi.string().valid('open', 'resolved', 'all'),
  type: Joi.string().valid('general', 'crypto', 'sports', 'business'),
  category: Joi.string(),
  creator: Joi.string(),
  search: Joi.string(),
  limit: Joi.number().integer().min(1),
  offset: Joi.number().integer().min(0)
});
