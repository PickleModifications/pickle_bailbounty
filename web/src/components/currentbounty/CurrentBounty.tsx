import { Button, Flex, Group, ScrollArea, useMantineTheme } from "@mantine/core";
import { TableScrollArea } from "../tablescrollarea/TableScrollArea";
import { useLocale } from "../../providers/locale/Locale";
import { Currency } from "../../providers/currency/Currency";
import { useState } from "react";
import { useBountyApp } from "../../providers/bounty/Bounty";
import { useNuiEvent } from "../../providers/nui/useNui";
import { IconPlus } from "@tabler/icons-react";
import { MenuModal } from "../menumodal/MenuModal";
import { fetchNui } from "../../providers/nui/fetchNui";
import { Search } from "../search/Search";
import { useConfig } from "../../providers/config/Config";
import { Risk } from "../bountypage/BountyPage";
import { Datetime } from "../datetime/Datetime";

export type CurrentBounty = {
    id: number;
    image?: string;
    risk?: number;
    description?: string;
    date: number;
    name: string;
    reward: number;
}

function CurrentBounty() {
    const theme = useMantineTheme();
    const translate = useLocale();
    const {config} = useConfig();
    const {bountyApp} = useBountyApp();
    const [currentBounty, setCurrentBounty] = useState<CurrentBounty | null>(bountyApp.currentBounty);

    useNuiEvent("updateBounty", function(data) {
        setCurrentBounty(data.bounty);
    });

    return (
        <Flex p={10} flex={1} w={"100%"} h={"100%"} pos={"relative"} style={{borderBottomLeftRadius: 5, borderBottomRightRadius: 5, backgroundColor: "transparent"}}>
            {currentBounty == null ? <>ERROR. NO CURRENT BOUNTY</> : (
                <Flex w={"100%"} gap={10} pl={10} pr={10} direction={"column"}>
                    <Flex align={"center"} gap={10}>
                        <img width={6 * 20} height={8 * 20} src={currentBounty.image || config.defaultPlayerImage}></img>
                        <Flex direction={"column"}>
                            <Flex gap={10}>
                                <b>{translate("available_bounties_name")}:</b>
                                {currentBounty.name}
                            </Flex>
                            <Flex gap={10}>
                                <b>{translate("available_bounties_date")}:</b>
                                {Datetime(currentBounty.date, config.currency.locale)}
                            </Flex>
                            <Flex gap={10}>
                                <b>{translate("available_bounties_reward")}:</b>
                                {Currency(currentBounty.reward, config)}
                            </Flex>
                            <Flex gap={10}>
                                {Risk(currentBounty.risk || 1, translate)}
                            </Flex>
                        </Flex>
                    </Flex>
                    <ScrollArea style={{ height: 100, color: theme.colors.dark[1]}}>
                        {currentBounty.description || "No description available."}
                    </ScrollArea>
                    <Button mt={"auto"} color={"red"} onClick={() => {
                        fetchNui("cancelCurrentBounty", { bounty: currentBounty }).then(() => {
                        });
                    }
                    }>{translate("current_bounty_cancel")}</Button>
                </Flex>
            )}
        </Flex>
    );
}

export default CurrentBounty;