package com.exasol.basetypes;

import java.util.BitSet;

/**
 * This class represents a 64 bit wide bit field.
 */
public class BitField64 {
    final BitSet bitField = new BitSet(64);

    /**
     * Create a bit field from a list of bits to set.
     *
     * @param bitIndices numbers of the bits to set (starting at zero)
     * @return bit field with given bits set
     */
    static final BitField64 ofIndices(final int... bitIndices) {
        return new BitField64(bitIndices);
    }

    /**
     * Create an empty bit field.
     *
     * @return empty bit field
     */
    static final BitField64 empty() {
        return new BitField64();
    }

    private BitField64(final int... bitIndices) {
        for (final int bitIndex : bitIndices) {
            set(bitIndex);
        }
    }

    private void validateBitIndex(final int bitIndex) {
        if ((bitIndex < 0) || (bitIndex > 63)) {
            throw new IllegalArgumentException("Setting bit " + bitIndex + " not allowed in 64 bit bit field.");
        }
    }

    /**
     * Set the bit at the given index.
     *
     * @param bitIndex index of the bit to be set.
     */
    public void set(final int bitIndex) {
        validateBitIndex(bitIndex);
        this.bitField.set(bitIndex);
    }

    /**
     * Clear the bit at the given index.
     *
     * @param bitIndex index of the bit to be cleared.
     */
    public void clear(final int bitIndex) {
        validateBitIndex(bitIndex);
        this.bitField.set(bitIndex, false);
    }

    /**
     * {@code long} representation of the bit field.
     *
     * @return {@code long} value representing the bit field
     */
    public long toLong() {
        return this.bitField.toLongArray()[0];
    }

    /***
     * Get the long representation of a bit field.
     * <p>
     * This is a convenience method. Equivalent to: <code>BitField64.ofIndices(bitIndices).toLong()</code>
     * </p>
     *
     * @param bitIndices numbers of the bits to set (starting at zero)
     * @return {@code long} value representing the bit field
     */
    public static long bitsToLong(final int... bitIndices) {
        return BitField64.ofIndices(bitIndices).toLong();
    }
}
