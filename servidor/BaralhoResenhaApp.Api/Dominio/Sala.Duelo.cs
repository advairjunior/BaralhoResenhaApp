namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Duelo: {jogador} contra {jogador2}. Os dois se apresentam, a turma vota em
/// quem mandou melhor e quem perde leva o ponto. Empate: os dois levam.
/// </summary>
public sealed partial class Sala
{
    private Revelacao RevelarDuelo(Rodada rodada, List<KeyValuePair<Guid, string>> respostas)
    {
        var votos = rodada.Duelistas
            .Where(id => _jogadores.Any(j => j.Id == id))
            .Select(id => new VotosRecebidos(id, respostas.Count(r => r.Value == id.ToString())))
            .OrderByDescending(v => v.Votos)
            .ToList();
        var maximo = votos.Count > 0 ? votos[0].Votos : 0;
        var vencedores = votos.Where(v => v.Votos == maximo).Select(v => v.JogadorId).ToList();
        var perderam = vencedores.Count > 1
            ? vencedores
            : votos.Select(v => v.JogadorId).Except(vencedores).ToList();
        if (vencedores.Count == 1)
            _jogadores.First(j => j.Id == vencedores[0]).Estatisticas.DuelosVencidos++;
        return new Revelacao([], [], votos, perderam, null) { Escolhidos = vencedores };
    }
}
