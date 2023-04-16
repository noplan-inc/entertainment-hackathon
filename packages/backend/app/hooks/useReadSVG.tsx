import { useCallback } from 'react';
import { useSigner, useContract } from 'wagmi';
import { BigNumber, Contract, Transaction } from 'ethers';
import zkWordleNFTAbi from '../../abi/zkWordleNFT.json';
import {base64} from 'ethers/lib/utils';

const defaultColors = Array(30).fill(1);

export const useReadSVG = () => {
    const { data: signer, isError, isLoading } = useSigner();

    const contract = useContract({
        address: '0xe7850330229ab5304a7Bb74b6af1e06BAAc55467',
        abi: zkWordleNFTAbi,
        signerOrProvider: signer,
    });

    const readSvg = useCallback(async (tokenId: BigNumber) => {
        if (!signer || !contract) return;

        const tokenURI = await contract.tokenURI(tokenId);

        const base64Encoded = tokenURI.split(",")[1];
        const decodedJsonStr = new TextDecoder().decode(base64.decode(base64Encoded));
        const base64Svg = JSON.parse(decodedJsonStr).image.split(",")[1];
        const svgImage = new TextDecoder().decode(base64.decode(base64Svg));
        return svgImage;
    }, [signer, contract]);


    return {readSvg, signer}
}