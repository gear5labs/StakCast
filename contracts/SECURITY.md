# StakCast Security Implementation

This document outlines the comprehensive security measures implemented in the StakCast prediction market smart contract.

## 🛡️ Security Features Overview

### 1. Access Control System

#### **Role-Based Access Control**
- **Admin**: Full control over the contract, can add/remove moderators, pause functions, and manage settings
- **Moderator**: Can create and resolve prediction markets
- **User**: Can place bets and collect winnings

#### **Implementation Details**
```cairo
// Admin-only functions
fn assert_only_admin(self: @ContractState) {
    let caller = get_caller_address();
    assert(self.admin.read() == caller, 'Only admin allowed');
}

// Moderator or Admin functions
fn assert_only_moderator_or_admin(self: @ContractState) {
    let caller = get_caller_address();
    let is_admin = self.admin.read() == caller;
    let is_moderator = self.moderators.read(caller);
    assert(is_admin || is_moderator, 'Only admin or moderator');
}
```

### 2. Emergency Pause Mechanism

#### **Multi-Level Pause System**
- **Global Pause**: Stops all contract functionality
- **Granular Pauses**: 
  - Market Creation Pause
  - Betting Pause
  - Resolution Pause

#### **Emergency Functions**
```cairo
fn emergency_pause(ref self: ContractState, reason: ByteArray)
fn emergency_unpause(ref self: ContractState)
fn pause_market_creation(ref self: ContractState)
fn pause_betting(ref self: ContractState)
fn pause_resolution(ref self: ContractState)
```

### 3. Time-Based Restrictions

#### **Market Duration Controls**
- **Minimum Duration**: 1 hour (configurable)
- **Maximum Duration**: 1 year (configurable)
- **Resolution Window**: 1 week after market end (configurable)

#### **Validation Logic**
```cairo
fn assert_valid_market_timing(self: @ContractState, end_time: u64) {
    let current_time = get_block_timestamp();
    let min_duration = self.min_market_duration.read();
    let max_duration = self.max_market_duration.read();
    
    assert(end_time > current_time, 'End time must be in future');
    assert(end_time - current_time >= min_duration, 'Market duration too short');
    assert(end_time - current_time <= max_duration, 'Market duration too long');
}
```

### 4. Market State Validation

#### **State Checks**
- Market existence validation
- Market open/closed status
- Resolution status
- Time-based availability

#### **Implementation**
```cairo
fn assert_market_open(self: @ContractState, market_id: u256, market_type: u8) {
    let current_time = get_block_timestamp();
    
    if market_type == 0 { // General prediction
        let market = self.predictions.entry(market_id).read();
        assert(market.is_open, 'Market is closed');
        assert(!market.is_resolved, 'Market already resolved');
        assert(current_time < market.end_time, 'Market has ended');
    }
    // Similar logic for crypto and sports predictions...
}
```

### 5. Reentrancy Protection

#### **Custom Reentrancy Guard**
```cairo
fn start_reentrancy_guard(ref self: ContractState) {
    assert(!self.reentrancy_guard.read(), 'Reentrant call');
    self.reentrancy_guard.write(true);
}

fn end_reentrancy_guard(ref self: ContractState) {
    self.reentrancy_guard.write(false);
}
```

#### **Protected Functions**
- Market creation
- Bet placement
- Market resolution
- Winnings collection

### 6. Input Validation

#### **Comprehensive Validation**
- Amount validation (positive values)
- Choice validation (valid indices)
- Address validation
- Time validation
- Market type validation

#### **Examples**
```cairo
fn assert_valid_amount(self: @ContractState, amount: u256) {
    assert(amount > 0, 'Amount must be positive');
}

fn assert_valid_choice(self: @ContractState, choice_idx: u8) {
    assert(choice_idx < 2, 'Invalid choice index');
}
```

## 🔒 Security Test Coverage

### Access Control Tests
- ✅ Admin can add moderators
- ✅ Non-admin cannot add moderators
- ✅ Moderators can create markets
- ✅ Regular users cannot create markets
- ✅ Only moderators/admin can resolve markets

### Time-Based Restriction Tests
- ✅ Cannot create markets with past end times
- ✅ Cannot create markets with too short duration
- ✅ Cannot create markets with too long duration
- ✅ Valid market durations work correctly

### Market State Validation Tests
- ✅ Betting works on open markets
- ✅ Cannot bet on ended markets
- ✅ Cannot bet zero amounts
- ✅ Cannot bet with invalid choice indices
- ✅ Cannot bet on non-existent markets

### Emergency Function Tests
- ✅ Emergency pause functionality (basic test)
- ⚠️ Pause integration tests (requires additional interface setup)
- ✅ Granular pause controls implemented

### Resolution Tests
- ✅ Markets can be resolved after end time
- ✅ Cannot resolve markets before end time
- ✅ Only authorized users can resolve
- ✅ Resolution window enforcement

### Edge Case Tests
- ✅ Multiple bets from same user
- ✅ Betting on different market types
- ✅ Complete market lifecycle
- ✅ Winnings calculation and collection

## 🚨 Security Considerations

### 1. Oracle Security
- **Price Feed Validation**: Crypto predictions use Pragma Oracle
- **Fallback Mechanisms**: Manual resolution available
- **Oracle Address Management**: Admin can update oracle

### 2. Economic Security
- **Fee Management**: Configurable platform fees (max 10%)
- **Value Locked Tracking**: Monitor total value in markets
- **Winnings Protection**: Secure calculation and distribution

### 3. Operational Security
- **Market Monitoring**: Statistics tracking for anomaly detection
- **Emergency Procedures**: Quick response capabilities
- **Batch Operations**: Efficient emergency market closure

### 4. Upgrade Security
- **Admin-Only Upgrades**: Contract upgrades restricted to admin
- **State Preservation**: Upgrade mechanism preserves user data

## 📊 Security Metrics

### Test Coverage
- **Total Tests**: 21 comprehensive test cases
- **Security Tests**: 15+ specific security scenarios
- **Edge Cases**: 8+ edge case validations
- **Integration Tests**: Full lifecycle testing

### Access Control Coverage
- ✅ Role-based permissions
- ✅ Function-level access control
- ✅ State-changing operation protection
- ✅ Emergency function restrictions

### State Validation Coverage
- ✅ Market existence checks
- ✅ Time-based validations
- ✅ Amount and choice validations
- ✅ Status consistency checks

## 🔧 Configuration Parameters

### Time Restrictions (Configurable by Admin)
```cairo
min_market_duration: u64 = 3600;      // 1 hour
max_market_duration: u64 = 31536000;  // 1 year
resolution_window: u64 = 604800;      // 1 week
```

### Fee Settings (Configurable by Admin)
```cairo
platform_fee_percentage: u256 = 250;  // 2.5% (basis points)
max_fee_percentage: u256 = 1000;      // 10% maximum
```

## 🚀 Deployment Security Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Security audit completed
- [ ] Access control verified
- [ ] Emergency procedures tested
- [ ] Oracle integration validated

### Post-Deployment
- [ ] Admin keys secured
- [ ] Moderators added
- [ ] Emergency contacts established
- [ ] Monitoring systems active
- [ ] Incident response plan ready

## 📞 Emergency Procedures

### Security Incident Response
1. **Immediate**: Call `emergency_pause()` with reason
2. **Assessment**: Analyze the security issue
3. **Communication**: Notify stakeholders
4. **Resolution**: Implement fix if needed
5. **Recovery**: Call `emergency_unpause()` when safe

### Contact Information
- **Admin**: Primary contract administrator
- **Security Team**: Emergency response team
- **Oracle Provider**: Pragma Labs for price feed issues

## 🔍 Audit Trail

All security-relevant events are logged:
- `ModeratorAdded` / `ModeratorRemoved`
- `EmergencyPaused`
- `MarketCreated` / `MarketResolved`
- `BetPlaced`

## 📚 Additional Resources

- [Cairo Security Best Practices](https://docs.starknet.io/documentation/architecture_and_concepts/Smart_Contracts/security-considerations/)
- [Starknet Security Guidelines](https://docs.starknet.io/documentation/architecture_and_concepts/Smart_Contracts/security/)
- [OpenZeppelin Cairo Contracts](https://docs.openzeppelin.com/contracts-cairo/)

---

**Note**: This security implementation follows industry best practices and includes comprehensive testing. Regular security audits and updates are recommended to maintain the highest security standards. 