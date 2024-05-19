__kernel void Encryption(__global uint* data, __global uint* key, __global uint* output)
{
	uint index = get_global_id(0); // work item ID

	uchar rotation = index%32;

	output[index] = data[index]^((*key << rotation) | (*key >> (32-rotation)));
}

__kernel void EncryptionAdvanced(__global uint* data, __global uint* key, __global uint* output)
{
	// worker ID
	uint index = get_global_id(0);

	// XOR the first five bits of the data and the rotation
	uchar xorRot = (*key&0b11111)^(index%32);

	uint newKey = *key^(xorRot<<27);

	// Rotate the key by the XOR rotation, square it and modulus it with 4294967311
	ulong rotated = ((newKey << xorRot) | (newKey >> (32-xorRot)))&0xffffffff;
	ulong keyMod = (rotated*rotated) % 4294967311;
	// XOR the modified key with the data
	output[index] = data[index]^keyMod;
}

