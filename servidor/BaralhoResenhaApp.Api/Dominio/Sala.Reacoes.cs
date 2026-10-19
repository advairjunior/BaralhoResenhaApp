namespace BaralhoResenhaApp.Api.Dominio;

/// <param name="Reacoes">Quantas de cada reação a carta rendeu.</param>
public sealed record CartaDaNoite(string Texto, IReadOnlyDictionary<string, int> Reacoes);

/// <summary>
/// Reação rápida na carta: cada um tem uma por carta, a turma vê a contagem
/// (sem saber quem reagiu) e a carta que mais rendeu vira a carta da noite.
/// </summary>
public sealed partial class Sala
{
    public static readonly IReadOnlyList<string> EmojisDeReacao = ["😂", "🔥", "💀", "😱"];

    /// <summary>Uma reação só é gosto de uma pessoa; carta da noite pede mais gente.</summary>
    private const int ReacoesParaCartaDaNoite = 2;

    private readonly List<Rodada> _rodadasComReacao = [];

    /// <summary>Reagir com a mesma de novo desfaz; com outra, troca.</summary>
    public void Reagir(string token, int numeroDaRodada, string emoji)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!EmojisDeReacao.Contains(emoji))
                throw new AcaoNaoPermitidaException("Essa reação não existe.");
            if (!RodadaEmAndamento(numeroDaRodada) || Fase is not (FaseDaSala.Carta or FaseDaSala.Revelada)) return;
            var rodada = Rodada!;
            if (rodada.Reacoes.GetValueOrDefault(jogador.Id) == emoji) rodada.Reacoes.Remove(jogador.Id);
            else rodada.Reacoes[jogador.Id] = emoji;
            if (!_rodadasComReacao.Contains(rodada)) _rodadasComReacao.Add(rodada);
            Tocar();
        }
    }

    /// <summary>Na ordem dos botões, só as que alguém usou.</summary>
    internal static IReadOnlyDictionary<string, int> ContarReacoes(Rodada rodada) => EmojisDeReacao
        .Select(emoji => (emoji, vezes: rodada.Reacoes.Values.Count(v => v == emoji)))
        .Where(contagem => contagem.vezes > 0)
        .ToDictionary(contagem => contagem.emoji, contagem => contagem.vezes);

    /// <summary>A carta com mais reações; no empate, a que saiu primeiro.</summary>
    internal CartaDaNoite? EscolherCartaDaNoite()
    {
        var campea = _rodadasComReacao
            .OrderByDescending(r => r.Reacoes.Count)
            .ThenBy(r => r.Numero)
            .FirstOrDefault();
        return campea is null || campea.Reacoes.Count < ReacoesParaCartaDaNoite
            ? null
            : new CartaDaNoite(campea.Texto, ContarReacoes(campea));
    }
}
