import { Protobuf } from "as-proto/assembly";
import { Events as protoEvents } from "./pb/starknet/v1/Events";
import {
  MarketCreated,
  PositionTaken,
  MarketResolved,
  WinningsClaimed,
  MarketDisputed,
  ValidatorRegistered,
  ValidatorSlashed,
  ValidatorActivated,
} from "../generated/schema";
import { BigInt, log, crypto, Bytes, json } from "@graphprotocol/graph-ts";

export function handleTriggers(bytes: Uint8Array): void {
  const input = Protobuf.decode<protoEvents>(bytes, protoEvents.decode);

  for (let i = 0; i < input.events.length; i++) {
    const event = input.events[i];

    const jsonDescription = json.fromBytes(
      Bytes.fromUTF8(event.jsonDescription)
    );

    if (!jsonDescription) continue;

    const jsonObj = jsonDescription.toObject();

    // Handle MarketCreated event
    if (jsonObj.get("MarketCreated")) {
      const marketCreated = jsonObj.get("MarketCreated")!.toObject();
      const _market_idAsBigInt = marketCreated.get("market_id")!.toBigInt();
      const _market_id = BigInt.fromString(_market_idAsBigInt.toString());
      const _creator = marketCreated.get("creator")!.toString();
      const _title = marketCreated.get("title")!.toString();
      const _startTimeAsBigInt = marketCreated.get("startTime")!.toBigInt();
      const _startTime = BigInt.fromString(_startTimeAsBigInt.toString());
      const _endTimeAsBigInt = marketCreated.get("startTime")!.toBigInt();
      const _endTime = BigInt.fromString(_endTimeAsBigInt.toString());

      // Create MarketCreated entity
      const marketCreatedId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _marketCreated = MarketCreated.load(marketCreatedId);
      if (!_marketCreated) {
        _marketCreated = new MarketCreated(marketCreatedId);
      }

      _marketCreated.market_id = _market_id;
      _marketCreated.creator = _creator;
      _marketCreated.title = _title;
      _marketCreated.startTime = _startTime;
      _marketCreated.endTime = _endTime;

      _marketCreated.save();
    }

    // Handle PositionTaken event
    if (jsonObj.get("PositionTaken")) {
      const positionTaken = jsonObj.get("PositionTaken")!.toObject();
      const _market_idAsBigInt = positionTaken.get("market_id")!.toBigInt();
      const _market_id = BigInt.fromString(_market_idAsBigInt.toString());
      const _user = positionTaken.get("user")!.toString();
      const _outcome_indexAsBigInt = positionTaken
        .get("outcome_index")!
        .toBigInt();
      const _outcome_index = BigInt.fromString(
        _outcome_indexAsBigInt.toString()
      );
      const _amountAsBigInt = positionTaken.get("amount")!.toBigInt();
      const _amount = BigInt.fromString(_amountAsBigInt.toString());

      // Create PositionTaken entity
      const positionTakenId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _positionTaken = PositionTaken.load(positionTakenId);
      if (!_positionTaken) {
        _positionTaken = new PositionTaken(positionTakenId);
      }

      _positionTaken.market_id = _market_id;
      _positionTaken.user = _user;
      _positionTaken.outcome_index = _outcome_index;
      _positionTaken.amount = _amount;

      _positionTaken.save();
    }

    // Handle MarketResolved event
    if (jsonObj.get("MarketResolved")) {
      const marketResolved = jsonObj.get("MarketResolved")!.toObject();
      const _market_idAsBigInt = marketResolved.get("market_id")!.toBigInt();
      const _market_id = BigInt.fromString(_market_idAsBigInt.toString());
      const _outcomeAsBigInt = marketResolved.get("outcome")!.toBigInt();
      const _outcome = BigInt.fromString(_outcomeAsBigInt.toString());
      const _resolver = marketResolved.get("resolver")!.toString();
      const _resolution_details = marketResolved
        .get("resolution_details")!
        .toString();

      // Create MarketResolved entity
      const marketResolvedId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _marketResolved = MarketResolved.load(marketResolvedId);
      if (!_marketResolved) {
        _marketResolved = new MarketResolved(marketResolvedId);
      }

      _marketResolved.market_id = _market_id;
      _marketResolved.outcome = _outcome;
      _marketResolved.resolver = _resolver;
      _marketResolved.resolution_details = _resolution_details;
      _marketResolved.save();
    }

    // Handle WinningsClaimed event
    if (jsonObj.get("WinningsClaimed")) {
      const winningsClaimed = jsonObj.get("WinningsClaimed")!.toObject();
      const _market_idAsBigInt = winningsClaimed.get("market_id")!.toBigInt();
      const _market_id = BigInt.fromString(_market_idAsBigInt.toString());
      const _user = winningsClaimed.get("user")!.toString();
      const _amountAsBigInt = winningsClaimed.get("amount")!.toBigInt();
      const _amount = BigInt.fromString(_amountAsBigInt.toString());

      // Create WinningsClaimed entity
      const winningsClaimedId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _winningsClaimed = WinningsClaimed.load(winningsClaimedId);
      if (!_winningsClaimed) {
        _winningsClaimed = new WinningsClaimed(winningsClaimedId);
      }

      _winningsClaimed.market_id = _market_id;
      _winningsClaimed.user = _user;
      _winningsClaimed.amount = _amount;

      _winningsClaimed.save();
    }

    // Handle MarketDisputed event
    if (jsonObj.get("MarketDisputed")) {
      const marketDisputed = jsonObj.get("MarketDisputed")!.toObject();
      const _market_idAsBigInt = marketDisputed.get("market_id")!.toBigInt();
      const _market_id = BigInt.fromString(_market_idAsBigInt.toString());
      const _disputer = marketDisputed.get("disputer")!.toString();
      const _reason = marketDisputed.get("reason")!.toString();

      // Create MarketDisputed entity
      const marketDisputedId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _marketDisputed = MarketDisputed.load(marketDisputedId);
      if (!_marketDisputed) {
        _marketDisputed = new MarketDisputed(marketDisputedId);
      }

      _marketDisputed.market_id = _market_id;
      _marketDisputed.disputer = _disputer;
      _marketDisputed.reason = _reason;

      _marketDisputed.save();
    }

    // Handle ValidatorRegistered event
    if (jsonObj.get("ValidatorRegistered")) {
      const validatorRegistered = jsonObj
        .get("ValidatorRegistered")!
        .toObject();
      const _validator = validatorRegistered.get("validator")!.toString();
      const _stakeAsBigInt = validatorRegistered.get("stake")!.toBigInt();
      const _stake = BigInt.fromString(_stakeAsBigInt.toString());

      // Create ValidatorRegistered entity
      const validatorRegisteredId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _validatorRegistered = ValidatorRegistered.load(
        validatorRegisteredId
      );
      if (!_validatorRegistered) {
        _validatorRegistered = new ValidatorRegistered(validatorRegisteredId);
      }

      _validatorRegistered.validator = _validator;
      _validatorRegistered.stake = _stake;

      _validatorRegistered.save();
    }

    // Handle ValidatorSlashed event
    if (jsonObj.get("ValidatorSlashed")) {
      const validatorSlashed = jsonObj.get("ValidatorSlashed")!.toObject();
      const _validator = validatorSlashed.get("validator")!.toString();
      const _amountAsBigInt = validatorSlashed.get("amount")!.toBigInt();
      const _amount = BigInt.fromString(_amountAsBigInt.toString());
      const _reason = validatorSlashed.get("reason")!.toString();

      // Create ValidatorSlashed entity
      const validatorSlashedId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _validatorSlashed = ValidatorSlashed.load(validatorSlashedId);
      if (!_validatorSlashed) {
        _validatorSlashed = new ValidatorSlashed(validatorSlashedId);
      }

      _validatorSlashed.validator = _validator;
      _validatorSlashed.amount = _amount;
      _validatorSlashed.reason = _reason;

      _validatorSlashed.save();
    }

    // Handle ValidatorActivated event
    if (jsonObj.get("ValidatorActivated")) {
      const validatorActivated = jsonObj.get("ValidatorActivated")!.toObject();
      const _validator = validatorActivated.get("validator")!.toString();
      const _activation_timeAsBigInt = validatorActivated
        .get("activation_time")!
        .toBigInt();
      const _activation_time = BigInt.fromString(
        _activation_timeAsBigInt.toString()
      );

      // Create ValidatorActivated entity
      const validatorActivatedId = crypto
        .keccak256(Bytes.fromUTF8(event.jsonDescription))
        .toHexString();
      let _validatorActivated = ValidatorActivated.load(validatorActivatedId);
      if (!_validatorActivated) {
        _validatorActivated = new ValidatorActivated(validatorActivatedId);
      }

      _validatorActivated.validator = _validator;
      _validatorActivated.activation_time = _activation_time;

      _validatorActivated.save();
    }
  }
}
