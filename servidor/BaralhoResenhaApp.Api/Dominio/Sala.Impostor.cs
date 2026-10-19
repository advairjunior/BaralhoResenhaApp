namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Impostor: todo mundo recebe a mesma palavra, menos um, que só sabe o tema.
/// Cada um fala uma pista em voz alta e a turma vota em quem é o impostor.
/// </summary>
public sealed partial class Sala
{
    /// <summary>
    /// Ordem das pistas: todo mundo, embaralhado, e o impostor nunca abre a
    /// roda (sem ouvir ninguém antes, ele se entrega na hora).
    /// </summary>
    private List<Guid> FilaDasPistas(Jogador impostor)
    {
        var fila = _jogadores.OrderBy(_ => _sorteio.Next()).Select(j => j.Id).ToList();
        if (fila[0] == impostor.Id) (fila[0], fila[^1]) = (fila[^1], fila[0]);
        return fila;
    }

    private void ValidarVotoNoImpostor(Jogador jogador, string resposta)
    {
        if (!(Guid.TryParse(resposta, out var votado) && _jogadores.Any(j => j.Id == votado)))
            throw new AcaoNaoPermitidaException("Vote em alguém da sala.");
        if (votado == jogador.Id)
            throw new AcaoNaoPermitidaException("Não vale votar em você.");
    }

    /// <summary>
    /// Pegaram só com o impostor sozinho no topo: no empate, a turma ficou em
    /// dúvida e ele escapa. Pegaram, ele leva o ponto; escapou, leva quem votou
    /// errado e ele ganha uma carta na manga.
    /// </summary>
    private Revelacao RevelarImpostor(Rodada rodada, List<KeyValuePair<Guid, string>> respostas)
    {
        var impostor = _jogadores.FirstOrDefault(j => j.Id == rodada.Impostor);
        var votos = respostas
            .GroupBy(r => Guid.Parse(r.Value))
            .Where(grupo => _jogadores.Any(j => j.Id == grupo.Key))
            .Select(grupo => new VotosRecebidos(grupo.Key, grupo.Count()))
            .OrderByDescending(v => v.Votos)
            .ToList();
        var maximo = votos.Count > 0 ? votos[0].Votos : 0;
        var maisVotados = votos.Where(v => v.Votos == maximo).Select(v => v.JogadorId).ToList();
        var pegaram = impostor is not null && maisVotados is [var unico] && unico == impostor.Id;

        IReadOnlyList<Guid> perderam;
        if (impostor is null) perderam = [];
        else if (pegaram) perderam = [impostor.Id];
        else
        {
            perderam = respostas
                .Where(r => r.Key != impostor.Id && r.Value != impostor.Id.ToString())
                .Select(r => r.Key)
                .ToList();
            impostor.Estatisticas.Disfarces++;
            DarCarta(impostor);
        }

        return new Revelacao([], [], votos, perderam, null)
        {
            Escolhidos = maisVotados,
            Impostor = impostor?.Id,
            Pegaram = pegaram,
        };
    }
}
