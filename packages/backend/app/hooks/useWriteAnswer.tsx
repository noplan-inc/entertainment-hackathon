import { useCallback } from 'react';
import { useSigner, useContract } from 'wagmi';
import { Contract } from 'ethers';
import zkWordleAbi from '../../abi/zkWordle.json';

const defaultColors = Array(30).fill(1);

export const useWriteAnswer = () => {
    const { data: signer, isError, isLoading } = useSigner();

    const contract = useContract({
        address: '0x22f5887ae1bc1E941090CCf00356F897856102dE',
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