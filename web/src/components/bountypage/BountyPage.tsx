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
import { Pill } from "../bailregistry/BailRegistry";
import { Datetime } from "../datetime/Datetime";

export type Bounty = {
    id: string;
    image?: string;
    risk?: number;
    description?: string;
    source?: number;
    bountyHunter?: number;
    date: number;
    name: string;
    reward: number;
}

export type Player = {
    source?: number;
    identifier: string;
    name: string;
    image?: string;
    reward?: number;
}

export function Risk(risk: number, translate: any) {
    const color = [
        "green",
        "yellow",
        "red"
    ];
    return <Pill c={color[risk - 1] || color[1]}>{translate("available_bounties_risk_" + risk)}</Pill>;
}

function BountyPage() {
    const theme = useMantineTheme();
    const translate = useLocale();
    const {config} = useConfig();
    const {bountyApp, setBountyApp} = useBountyApp();
    const [bounties, setBounties] = useState<Bounty[]>(bountyApp.bounties);
    const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null);
    const [players, setPlayers] = useState<Player[]>([
        {
            source: 1,
            identifier: "steam:123456",
            name: "John Doe"
        },
        {
            source: 2,
            identifier: "steam:654321",
            name: "Jane Smith"
        },
        {
            source: 3,
            identifier: "steam:112233",
            name: "Alice Johnson"
        },
        {
            source: 4,
            identifier: "steam:445566",
            name: "Bob Brown"
        },
        {
            source: 5,
            identifier: "steam:778899",
            name: "Charlie Davis"
        },
        {
            source: 6,
            identifier: "steam:998877",
            name: "David Wilson"
        },
        {
            source: 7,
            identifier: "steam:223344",
            name: "Eve White"
        },
        {
            source: 8,
            identifier: "steam:556677",
            name: "Frank Green"
        },
        {
            source: 9,
            identifier: "steam:889900",
            name: "Grace Black"
        },
        {
            source: 10,
            identifier: "steam:334455",
            name: "Hank Blue"
        },
        {
            source: 11,
            identifier: "steam:667788",
            name: "Ivy Red"
        },
        {
            source: 12,
            identifier: "steam:990011",
            name: "Jack Yellow"
        },
        {
            source: 13,
            identifier: "steam:112244",
            name: "Karen Purple"
        },
        {
            source: 14,
            identifier: "steam:334466",
            name: "Leo Orange"
        },
        {
            source: 15,
            identifier: "steam:556688",
            name: "Mia Pink"
        },
        {
            source: 16,
            identifier: "steam:778800",
            name: "Nina Gray"
        }
    ]);
    const [search, setSearch] = useState("");
    const [addingPlayer, setAddingPlayer] = useState(false);
    const [viewBounty, setViewBounty] = useState<Bounty | null>(null);
    const [viewingBounty, setViewingBounty] = useState(false);
    const inputStyle = {
        background: theme.colors.dark[6], 
        color: "white", 
        border: "none", 
        padding: "5px 5px"
    }
    let filteredPlayers = []
    let playersFiltered = 0;
    let morePlayers = false;
    for (let i = 0; i < players.length; i++) {
        let player = players[i];
        if (player.name.toLowerCase().includes(search) || player.source?.toString().includes(search)) {
            if (playersFiltered >= 10) {
                morePlayers = true;
                break;
            }
            filteredPlayers.push(player);
            playersFiltered++;
        }
    }
    let filteredBounties = bounties.filter((bounty) => {
        if (!bounty.id.startsWith("npc:") && (bounty.source == null || bounty.source < 1)) {
            return false;
        }
        return (bounty.bountyHunter == null || bounty.bountyHunter < 1);
    });

    useNuiEvent("updateBounties", function(data) {
        setBounties(data.bounties);
    });

    return (
        <Flex p={10} flex={1} w={"100%"} h={"100%"} pos={"relative"} style={{borderBottomLeftRadius: 5, borderBottomRightRadius: 5, backgroundColor: "transparent"}}>
            <TableScrollArea defaultSort={{column: 2, descending: false}} data={{
                caption: translate("header_bounty"),
                head: ["", translate("available_bounties_name"), translate("available_bounties_date"),  translate("available_bounties_reward"), translate("available_bounties_risk"), ''],
                body: filteredBounties.map((bounty, bountyIndex) => [
                    <img src={bounty.image || config.defaultPlayerImage} alt={bounty.name} width={6 * 6} height={8 * 6}/>,
                    bounty.name, 
                    Datetime(bounty.date, config.currency.locale),
                    Currency(bounty.reward, config),
                    `(${bounty.risk || 1}) `+ translate("available_bounties_risk_" + (bounty.risk || 1)),
                    <Button size="xs" color={"dark.7"} onClick={() => {
                        setViewBounty(bounty)
                        setViewingBounty(true)
                    }}>{translate("available_bounties_view")}</Button>
                ])
            }} options={config.permissions.bailManage && (<Button color={"dark.5"} onClick={() => {
                fetchNui<{ players: Player[] }>("getPlayers", {}).then((data) => {
                    setAddingPlayer(true)
                    setPlayers(data.players);
                });
            }}><IconPlus style={{marginRight: 10}}/>{translate("select_player_add_bounty")}</Button>)}/>
            <MenuModal title={translate("add_new_bounty")} close={() => {
                setAddingPlayer(false);
                setTimeout(() => {
                    setSelectedPlayer(null);
                }, 200);
            }} visible={addingPlayer}>
                {selectedPlayer ? (
                    <Flex gap={10} pl={10} pr={10} direction={"column"}>
                        <Group gap={5} w={"100%"} p={10} bg={"dark.6"}>
                            <Flex>{selectedPlayer.name}</Flex>
                            <Flex>{translate("player_source", selectedPlayer.source)}</Flex>
                        </Group>
                        <Flex gap={5} direction={"column"}>
                            <label>{translate("bounty_image_url")}</label>
                            <input style={inputStyle} type="text" onChange={(e) => {
                                setSelectedPlayer({
                                    ...selectedPlayer,
                                    image: e.target.value
                                });
                            }} />
                        </Flex>
                        <Flex gap={5} direction={"column"}>
                            <label>{translate("bounty_reward_amount")}</label>
                            
                            <input min={0} max={config.bailOfficers.maximumBailAmount || 0} style={inputStyle} type="number" onChange={(e) => {
                                setSelectedPlayer({
                                    ...selectedPlayer,
                                    reward: parseFloat(e.target.value)
                                });
                            }} />
                        </Flex>
                        <Flex gap={5} direction={"column"}>
                            <Button color={"green"} onClick={() => {
                                fetchNui("addPlayerToBounty", { player: selectedPlayer }).then(() => {
                                    setAddingPlayer(false);
                                    setTimeout(() => {
                                        setSelectedPlayer(null);
                                    }, 200);
                                });
                            }}>{translate("select_player_add_bounty")}</Button>
                            <Button color={"dark.5"} onClick={() => {
                                setSelectedPlayer(null);
                            }}>{translate("select_player_back")}</Button>
                        </Flex>
                    </Flex>
                ) : (
                    <Flex gap={20} pl={10} pr={10} direction={"column"}>
                        <Flex gap={5} direction={"column"}>
                            <div style={{color: theme.colors.dark[3]}}>Showing {filteredPlayers.length} / {players.length} player(s)</div>
                            <Search size='xs' onChange={(event) => {
                                setSearch(event.currentTarget.value.toLowerCase());
                            }}/>
                        </Flex>
                        <ScrollArea h={220}>
                            <Flex gap={5} direction={"column"}> 
                                {filteredPlayers.length < 1 ? "No players to select." : filteredPlayers.map((player, playerIndex) => {
                                    return (
                                        <Group onClick={() => setSelectedPlayer(player)} style={{cursor: "pointer", userSelect: "none"}} gap={5} w={"100%"} p={10} key={playerIndex} bg={"dark.6"}>
                                            <Flex>{player.name}</Flex>
                                            <Flex>{translate("player_source", player.source)}</Flex>
                                        </Group>    
                                    )
                                })}     
                            </Flex>
                        </ScrollArea>
                    </Flex>
                )}
            </MenuModal>
            <MenuModal title={translate("view_bounty")} close={() => {
                setViewingBounty(false);
                setTimeout(() => {
                    setViewBounty(null);
                }, 200);
            }} visible={viewingBounty}>
                {viewBounty && (
                    <Flex gap={10} pl={10} pr={10} direction={"column"}>
                        <Flex align={"center"} gap={10}>
                            <img width={6 * 12} height={8 * 12} src={viewBounty.image || config.defaultPlayerImage}></img>
                            <Flex direction={"column"}>
                                <Flex gap={10}>
                                    <b>{translate("available_bounties_name")}:</b>
                                    {viewBounty.name}
                                </Flex>
                                <Flex gap={10}>
                                    <b>{translate("available_bounties_date")}:</b>
                                    {Datetime(viewBounty.date, config.currency.locale)}
                                </Flex>
                                <Flex gap={10}>
                                    <b>{translate("available_bounties_reward")}:</b>
                                    {Currency(viewBounty.reward, config)}
                                </Flex>
                                <Flex gap={10}>
                                    {Risk(viewBounty.risk || 1, translate)}
                                </Flex>
                            </Flex>
                        </Flex>
                        <ScrollArea style={{ height: 100, color: theme.colors.dark[1]}}>
                            {viewBounty.description || "No description available."}
                        </ScrollArea>
                        {config.permissions.bountyHunter && (<Button color={"green"} onClick={() => {
                            fetchNui("acceptBounty", { bounty: viewBounty }).then(() => {
                                setViewingBounty(false);
                            });
                        }}>{translate("available_bounties_accept")}</Button>)}
                        {config.permissions.bailManage && (<Button color={"red"} onClick={() => {
                            fetchNui("declineBounty", { bounty: viewBounty }).then(() => {
                                setViewingBounty(false);
                            });
                        }
                        }>{translate("available_bounties_remove")}</Button>)}
                    </Flex>
                )}
            </MenuModal>
        </Flex>
    )
}

export default BountyPage;