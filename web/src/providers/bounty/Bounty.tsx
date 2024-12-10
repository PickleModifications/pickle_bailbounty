import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from '../nui/useNui';
import { Bounty } from '../../components/bountypage/BountyPage';
import { CurrentBounty } from '../../components/currentbounty/CurrentBounty';
import { Bail } from '../../components/bailregistry/BailRegistry';

type Locale = {
    [key: string]: string;
}

type BountyAppData = {
    currentBounty: CurrentBounty | null;
    bounties: Bounty[];
    bailRegistry: Bail[];
}

interface BountyAppContextProps {
    bountyApp: BountyAppData;
    setBountyApp: (newBountyApp: BountyAppData) => void;
}

const BountyAppContext = createContext<BountyAppContextProps | undefined>(undefined);

interface BountyAppProviderProps {
    children: ReactNode;
}

export const BountyAppProvider: React.FC<BountyAppProviderProps> = ({ children }) => {
    const [bountyApp, setBountyApp] = useState<BountyAppData>({
        currentBounty: null,
        bounties: [],    
        bailRegistry: [],    
    });

    useNuiEvent("updateBailRegistry", function(data) {
        bountyApp.bailRegistry = data.bailRegistry;
        setBountyApp(bountyApp);
    });
    useNuiEvent("updateBounties", function(data) {
        bountyApp.bounties = data.bounties;
        setBountyApp(bountyApp);
    });
    useNuiEvent("updateBounty", function(data) {
        bountyApp.currentBounty = data.bounty;
        setBountyApp(bountyApp);
    });
    return (
        <BountyAppContext.Provider value={{ bountyApp, setBountyApp }}>
            {children}
        </BountyAppContext.Provider>
    );
};

export const useBountyApp = (): BountyAppContextProps => {
    const context = useContext(BountyAppContext);
    if (!context) {
        throw new Error('useBountyApp must be used within a BountyAppProvider');
    }
    return context;
};