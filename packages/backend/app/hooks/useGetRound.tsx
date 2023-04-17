import { useCallback } from 'react';
import { useSigner, useContract } from 'wagmi';
import zkWordleAbi from '../../abi/zkWordle.json';

export const useGetRound = () => {
    const { data: signer, isError, isLoading } = useSigner();

    const contract = useContract({
        address: '0xEF7AaeCE5d11e0BE9a3065a67bD8Ede62F8a783d',
        abi: zkWordleAbi,
        signerOrProvider: signer,
    });

    const getRound = useCallback(async () => {
        if (!signer || !contract) return;
        // console.log(proof);
        // console.log(word);
        // console.log(colors)
        const round = await contract.round();
        return round;
    }, [signer, contract]);


    return {getRound, signer}
}