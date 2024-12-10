import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from '../nui/useNui';

type Locale = {
    [key: string]: string;
}

export type Config = {
    loaded?: boolean;
    locale: Locale;
    defaultPlayerImage: string;
    permissions: {
        bountyHunter: boolean;
        bailPlacement: boolean;
        bailManage: boolean;
    };
    bailOfficers: {
        maximumBailAmount: number;
    };
    currency: {
        name: string;
        locale: string;
    };
}

interface ConfigContextProps {
    config: Config;
    setConfig: (newConfig: Config) => void;
}

const ConfigContext = createContext<ConfigContextProps | undefined>(undefined);

interface ConfigProviderProps {
    children: ReactNode;
}

export const ConfigProvider: React.FC<ConfigProviderProps> = ({ children }) => {
    const [config, setConfig] = useState<Config>({
        locale: {},
        defaultPlayerImage: "unknown_player.png",
        bailOfficers: {
            maximumBailAmount: 0
        },
        permissions: {
            bountyHunter: false,
            bailPlacement: false,
            bailManage: false
        },
        currency: {
            name: "USD",
            locale: "en-US"
        }
    });

    useNuiEvent("setConfig", function(config) {
        setConfig(config);
      });

    useNuiEvent("updatePermissions", function(data) {
        setConfig((prev) => ({
            ...prev,
            permissions: {
                ...prev.permissions,
                ...data.permissions
            }
        }));
    });
    
    return (
        <ConfigContext.Provider value={{ config, setConfig }}>
            {children}
        </ConfigContext.Provider>
    );
};

export const useConfig = (): ConfigContextProps => {
    const context = useContext(ConfigContext);
    if (!context) {
        throw new Error('useConfig must be used within a ConfigProvider');
    }
    return context;
};