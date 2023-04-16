import { useCallback } from 'react';
import { useSigner, useContract } from 'wagmi';
import { Contract } from 'ethers';
import zkWordleAbi from '../../abi/zkWordle.json';

const defaultColors = Array(30).fill(1);

export const useWriteAnswer = () => {
    const { data: signer, isError, isLoading } = useSigner();

    const contract = useContract({
        address: '0xEF7AaeCE5d11e0BE9a3065a67bD8Ede62F8a783d',
        abi: zkWordleAbi,
        signerOrProvider: signer,
    })

    const writeAnswer = useCallback(async (proof: any, word: string, colors = defaultColors) => {
        if (!signer || !contract) return;
        console.log(proof);
        console.log(word);
        console.log(colors)
        const tx = await contract.answer(proof, word, colors);
        await tx.wait();
    }, [signer, contract]);


    return {writeAnswer, signer}
}