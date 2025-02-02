// Code taken from https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol

// @authors:
// Gav Wood <g@ethdev.com>
// inheritable "property" contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.

pragma solidity 0.6.12;

contract Multiowned {

	// TYPES

    // struct for the status of a pending operation.
    struct PendingState {
        uint yetNeeded;
        uint ownersDone;
        uint index;
    }

	// EVENTS

    // this contract only has six types of events: it can accept a confirmation, in which case
    // we record owner and operation (hash) alongside it.
    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    // some others are in the case of an owner changing.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);
    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

	// MODIFIERS

    // simple single-sig function modifier.
    modifier onlyowner {
        require(isOwner(msg.sender), "No authorize");
        _;
    }

	// METHODS

    // constructor is given number of sigs required to do protected "onlymanyowners" transactions
    // as well as the selection of addresses capable of confirming them.
    constructor (address[] memory _owners, uint _required) public {
        m_numOwners = _owners.length + 1;
        m_owners[1] = uint(msg.sender);
        m_ownerIndex[uint(msg.sender)] = 1;
        for (uint i = 0; i < _owners.length; ++i)
        {
            m_owners[2 + i] = uint(_owners[i]);
            m_ownerIndex[uint(_owners[i])] = 2 + i;
        }
        m_required = _required;
    }

    // make a multi owner proxy to target
    function proxy(address target, bytes memory data) external onlyowner {
        if (!confirmAndCheck(keccak256(msg.data))) {
           return;
        }
        (bool success, ) = target.call(data);
        require(success, "proxy failed");
    }

    // Revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external onlyowner {
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        uint ownerIndexBit = 2**ownerIndex;
        PendingState storage pending = m_pending[_operation];
        if (pending.ownersDone & ownerIndexBit > 0) {
            pending.yetNeeded++;
            pending.ownersDone -= ownerIndexBit;
            emit Revoke(msg.sender, _operation);
        }
    }

    // Replaces an owner `_from` with another `_to`.
    function changeOwner(address _from, address _to) external onlyowner {
        if (isOwner(_to)) return;
        uint ownerIndex = m_ownerIndex[uint(_from)];
        if (ownerIndex == 0) return;

        if (!confirmAndCheck(keccak256(msg.data))) {
            return;
        }

        clearPending();
        m_owners[ownerIndex] = uint(_to);
        m_ownerIndex[uint(_from)] = 0;
        m_ownerIndex[uint(_to)] = ownerIndex;
        OwnerChanged(_from, _to);
    }

    function addOwner(address _owner) external onlyowner {
        if (isOwner(_owner)) return;

        if (!confirmAndCheck(keccak256(msg.data))) {
            return;
        }

        clearPending();
        if (m_numOwners >= c_maxOwners)
            reorganizeOwners();
        if (m_numOwners >= c_maxOwners)
            return;
        m_numOwners++;
        m_owners[m_numOwners] = uint(_owner);
        m_ownerIndex[uint(_owner)] = m_numOwners;
        emit OwnerAdded(_owner);
    }

    function removeOwner(address _owner) external onlyowner {
        uint ownerIndex = m_ownerIndex[uint(_owner)];
        if (ownerIndex == 0) return;
        if (m_required > m_numOwners - 1) return;

        if (!confirmAndCheck(keccak256(msg.data))) {
            return;
        }

        m_owners[ownerIndex] = 0;
        m_ownerIndex[uint(_owner)] = 0;
        clearPending();
        reorganizeOwners(); //make sure m_numOwner is equal to the number of owners and always points to the optimal free slot
        emit OwnerRemoved(_owner);
    }

    function changeRequirement(uint _newRequired) external onlyowner {
        if (_newRequired > m_numOwners) return;

        if (!confirmAndCheck(keccak256(msg.data))) {
            return;
        }

        m_required = _newRequired;
        clearPending();
        emit RequirementChanged(_newRequired);
    }

    // Gets an owner by 0-indexed position (using numOwners as the count)
    function getOwner(uint ownerIndex) public view returns (address) {
        return address(m_owners[ownerIndex + 1]);
    }

    function isOwner(address _addr) public view returns (bool) {
        return m_ownerIndex[uint(_addr)] > 0;
    }

    function hasConfirmed(bytes32 _operation, address _owner) public view returns (bool) {
        PendingState storage pending = m_pending[_operation];
        uint ownerIndex = m_ownerIndex[uint(_owner)];

        // make sure they're an owner
        if (ownerIndex == 0) return false;

        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        return !(pending.ownersDone & ownerIndexBit == 0);
    }

    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation) internal returns (bool) {
        // determine what index the present sender is:
        uint ownerIndex = m_ownerIndex[uint(msg.sender)];
        // make sure they're an owner
        if (ownerIndex == 0) return false;

        PendingState storage pending = m_pending[_operation];
        // if we're not yet working on this operation, switch over and reset the confirmation status.
        if (pending.yetNeeded == 0) {
            // reset count of confirmations needed.
            pending.yetNeeded = m_required;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_pendingIndex.length;
            m_pendingIndex.push(_operation);
        }
        // determine the bit to set for this owner.
        uint ownerIndexBit = 2**ownerIndex;
        // make sure we (the message sender) haven't confirmed this operation previously.
        if (pending.ownersDone & ownerIndexBit == 0) {
            emit Confirmation(msg.sender, _operation);
            // ok - check if count is enough to go ahead.
            if (pending.yetNeeded <= 1) {
                // enough confirmations: reset and run interior.
                delete m_pendingIndex[m_pending[_operation].index];
                delete m_pending[_operation];
                return true;
            }
            else
            {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
            }
        }
        return false;
    }

    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
            while (free < m_numOwners && m_owners[free] != 0) free++;
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() internal {
        uint length = m_pendingIndex.length;
        for (uint i = 0; i < length; ++i)
            if (m_pendingIndex[i] != 0)
                delete m_pending[m_pendingIndex[i]];
        delete m_pendingIndex;
    }

   	// FIELDS

    // the number of owners that must confirm the same operation before it is run.
    uint public m_required;
    // pointer used to find a free slot in m_owners
    uint public m_numOwners;

    // list of owners
    uint[256] public m_owners;
    uint public constant c_maxOwners = 250;
    // index on the list of owners to allow reverse lookup
    mapping(uint => uint) public m_ownerIndex;
    // the ongoing operations.
    mapping(bytes32 => PendingState) public m_pending;
    bytes32[] public m_pendingIndex;
}
