namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// ✍️ Quem escreveu?: a escrita é a do Termine a frase (secreta, embaralhada).
/// Uma resposta vai para o centro e todo mundo vota em quem escreveu, inclusive
/// o autor, para não se entregar; o voto dele não conta. Errou, leva ponto;
/// ninguém acertou, o autor escapou: carta na manga e passa a vez de distribuir.
/// </summary>
public sealed partial class Sala
{
    /// <summary>A resposta da pessoa: cabe uma história curta, não um textão.</summary>
    internal const int TamanhoDaResposta = 60;

    /// <summary>Com duas respostas, cada um sabe que a outra é do outro.</summary>
    internal const int MinimoDeRespostas = 3;

    private void ValidarVotoNoAutor(Jogador jogador, string resposta)
    {
        if (!Guid.TryParse(resposta, out var votado) || !_jogadores.Any(j => j.Id == votado))
            throw new AcaoNaoPermitidaException("Vote em quem você acha que escreveu.");
        if (votado == jogador.Id)
            throw new AcaoNaoPermitidaException("Vote em outra pessoa: você sabe se foi você.");
    }

    private Revelacao RevelarQuemEscreveu(Rodada rodada, List<KeyValuePair<Guid, string>> respostas)
    {
        var ordem = rodada.OrdemDasFrases ?? [];
        var autor = rodada.FraseEmJogo is { } indice && indice < ordem.Count ? ordem[indice] : Guid.Empty;
        var votos = respostas.Where(r => r.Key != autor).ToList();
        var acertaram = votos.Where(r => r.Value == autor.ToString()).Select(r => r.Key).ToList();
        var erraram = votos.Where(r => r.Value != autor.ToString()).Select(r => r.Key).ToList();
        var escapou = acertaram.Count == 0 && _jogadores.FirstOrDefault(j => j.Id == autor) is { } quem ? quem : null;
        if (escapou is not null) DarCarta(escapou);

        var recebidos = votos
            .GroupBy(r => r.Value)
            .Select(g => new VotosRecebidos(Guid.Parse(g.Key), g.Count()))
            .OrderByDescending(v => v.Votos)
            .ToList();
        return new Revelacao([], [], recebidos, erraram, null, Elogio: escapou is not null)
        {
            Escolhidos = escapou is null ? [] : [escapou.Id],
            Acertaram = acertaram,
            // Só a resposta do centro revela quem escreveu; as outras ficam anônimas.
            Frases = ordem
                .Select(id => new FraseRevelada(rodada.Frases[id], 0, id == autor ? autor : null))
                .ToList(),
        };
    }
}
