namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Duelo de pedra, papel e tesoura: os dois sorteados escolhem em segredo
/// no celular e o app revela. Empate: joguem de novo, na mesma carta.
/// </summary>
public sealed partial class Sala
{
    public const string Pedra = "pedra";
    public const string Papel = "papel";
    public const string Tesoura = "tesoura";

    private static readonly IReadOnlyDictionary<string, string> GanhaDe = new Dictionary<string, string>
    {
        [Pedra] = Tesoura,
        [Tesoura] = Papel,
        [Papel] = Pedra,
    };

    private static string ValidarJogada(Rodada rodada, Jogador jogador, string resposta)
    {
        if (!rodada.Duelistas.Contains(jogador.Id))
            throw new AcaoNaoPermitidaException("Só os dois do duelo jogam. Torce aí!");
        if (resposta is not (Pedra or Papel or Tesoura))
            throw new AcaoNaoPermitidaException("Escolha pedra, papel ou tesoura.");
        return resposta;
    }

    /// <summary>Com os dois jogados: empate zera a mão; senão, revela quem ganhou.</summary>
    private void ResolverJokenpo(Rodada rodada)
    {
        if (!rodada.Duelistas.All(rodada.Respostas.ContainsKey)) return;
        var (primeiro, segundo) = (rodada.Duelistas[0], rodada.Duelistas[1]);
        var (jogadaDoPrimeiro, jogadaDoSegundo) = (rodada.Respostas[primeiro], rodada.Respostas[segundo]);
        if (jogadaDoPrimeiro == jogadaDoSegundo)
        {
            rodada.Empates.Add(jogadaDoPrimeiro);
            rodada.Respostas.Clear();
            return;
        }

        var (vencedor, perdedor) = GanhaDe[jogadaDoPrimeiro] == jogadaDoSegundo
            ? (primeiro, segundo)
            : (segundo, primeiro);
        rodada.Revelacao = new Revelacao([], [], [], [perdedor], null)
        {
            Escolhidos = [vencedor],
            Jogadas = new Dictionary<Guid, string> { [primeiro] = jogadaDoPrimeiro, [segundo] = jogadaDoSegundo }
        };
        if (_jogadores.FirstOrDefault(j => j.Id == vencedor) is { } ganhou) ganhou.Estatisticas.DuelosVencidos++;
        if (_jogadores.FirstOrDefault(j => j.Id == perdedor) is { } perdeu) Punir(perdeu);
        Fase = FaseDaSala.Revelada;
    }
}
