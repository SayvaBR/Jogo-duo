// Optional Jogo Duo house rule: bank a six, roll again, and assign both dice independently.
// Keep the canonical Ludo rules in engine.ts untouched.
import { ludoMove, ludoOptions, ludoRoll, newLudo, nextLudo } from './engine';
import type { LudoState } from './engine';

export interface ComboLudoState extends LudoState {
  banked: number[];
  combined: boolean;
  extraAfterCombo: boolean;
  captureBonus: boolean;
}
export const newComboLudo = (players: 2 | 3 | 4): ComboLudoState => ({
  ...newLudo(players), banked: [], combined: false, extraAfterCombo: false, captureBonus: false
});
const clearCombo = (state: ComboLudoState): ComboLudoState => ({
  ...state, banked: [], combined: false, extraAfterCombo: false, captureBonus: false
});
const nextPlayer = (state: ComboLudoState, message: string): ComboLudoState =>
  clearCombo({ ...nextLudo(state), message });

export function canBankSix(state: ComboLudoState): boolean {
  return state.phase === 'move' && state.die === 6 && !state.combined && state.banked.length === 0 &&
    state.tokens[state.current].filter(position => position >= 0 && position < 56).length >= 2;
}
export function bankSix(state: ComboLudoState): ComboLudoState {
  if (!canBankSix(state)) return state;
  return { ...state, die: null, banked: [6], combined: true, phase: 'roll',
    message: '6 guardado! Lance o dado novamente; depois escolha como distribuir os dois valores.' };
}
export function comboRoll(state: ComboLudoState, value: number): ComboLudoState {
  if (state.phase !== 'roll' || !Number.isInteger(value) || value < 1 || value > 6) return state;
  // The saved 6 has already granted its additional throw; both dice must be spent.
  if (state.combined && state.banked.length === 1) {
    if (value === 6 && state.sixes === 2) return nextPlayer(state, 'Três seis seguidos: perdeu a vez e os dados guardados.');
    return { ...state, die: state.banked[0], banked: [value], phase: 'move',
      sixes: value === 6 ? state.sixes + 1 : 0, extraAfterCombo: value === 6,
      message: `Dados: 6 e ${value}. Escolha um dado e depois a peça.` };
  }
  const rolled = ludoRoll(state, value) as ComboLudoState;
  // Standard play stays identical, including the third-six penalty.
  return clearCombo(rolled);
}
export function chooseComboDie(state: ComboLudoState): ComboLudoState {
  if (state.phase !== 'move' || !state.combined || state.die === null || state.banked.length !== 1) return state;
  return { ...state, die: state.banked[0], banked: [state.die],
    message: `Dado ${state.banked[0]} selecionado. Escolha a peça que vai receber esse movimento.` };
}
function finishCombo(state: ComboLudoState, note: string): ComboLudoState {
  if (state.extraAfterCombo || state.captureBonus) {
    return clearCombo({ ...state, die: null, phase: 'roll',
      message: `${note} ${state.extraAfterCombo ? 'O segundo 6 concede nova jogada.' : 'Captura concede nova jogada.'}` });
  }
  return nextPlayer(state, `${note} Próximo jogador.`);
}
export function comboMove(state: ComboLudoState, token: number): ComboLudoState {
  if (!state.combined) return clearCombo(ludoMove(state, token) as ComboLudoState);
  if (state.die === null || !ludoOptions(state).includes(token) || state.phase !== 'move') return state;
  const applied = ludoMove(state, token);
  if (applied === state) return state;
  const captured = state.players.some(player => player !== state.current &&
    state.tokens[player].some((position, index) => position >= 0 && applied.tokens[player][index] === -1));
  const updated: ComboLudoState = { ...state, tokens: applied.tokens,
    captureBonus: state.captureBonus || captured };
  if (applied.winner !== null) return clearCombo({ ...updated, phase: 'done', die: null,
    winner: applied.winner, message: 'Partida encerrada!' });
  if (state.banked.length) {
    const second = state.banked[0];
    const remaining: ComboLudoState = { ...updated, die: second, banked: [], phase: 'move',
      message: `Primeiro movimento concluído! Agora use o dado ${second}.` };
    if (ludoOptions(remaining).length) return remaining;
    return finishCombo(remaining, `Não há jogada possível para o dado ${second}.`);
  }
  return finishCombo(updated, captured ? 'Você capturou uma peça!' : 'Os dois dados foram utilizados.');
}
